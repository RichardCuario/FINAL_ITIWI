const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('Missing Supabase environment variables');
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const tableName = 'transparency_executive_orders';
const storageBucket = 'transparency-pdfs';

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const includeAll = req.query.include_all === 'true';

      let query = supabase
        .from(tableName)
        .select('*')
        .order('display_order', { ascending: true })
        .order('created_at', { ascending: false });

      if (!includeAll) {
        query = query.eq('is_published', true);
      }

      const { data, error } = await query;

      if (error) {
        return res.status(500).json({ error: error.message });
      }

      return res.status(200).json({ data: data || [] });
    }

    if (req.method === 'POST') {
      const {
        title,
        description = null,
        pdfBase64,
        fileName,
        is_published = false,
        display_order = 0,
      } = req.body || {};

      if (!title || !pdfBase64 || !fileName) {
        return res.status(400).json({ error: 'title, pdfBase64, and fileName are required.' });
      }

      const sanitizedFileName = String(fileName).replace(/[^a-zA-Z0-9._-]/g, '_');
      const filePath = `${tableName}/${Date.now()}-${sanitizedFileName}`;
      const base64Payload = String(pdfBase64).includes(',')
        ? String(pdfBase64).split(',').pop()
        : String(pdfBase64);
      const pdfBuffer = Buffer.from(base64Payload, 'base64');

      const { error: uploadError } = await supabase.storage
        .from(storageBucket)
        .upload(filePath, pdfBuffer, {
          contentType: 'application/pdf',
          upsert: false,
        });

      if (uploadError) {
        return res.status(500).json({ error: uploadError.message });
      }

      const { data: publicUrlData } = supabase.storage
        .from(storageBucket)
        .getPublicUrl(filePath);

      const pdf_url = publicUrlData?.publicUrl || null;

      const { data, error } = await supabase
        .from(tableName)
        .insert([
          {
            title,
            description,
            pdf_url,
            is_published,
            display_order,
          },
        ])
        .select()
        .single();

      if (error) {
        await supabase.storage.from(storageBucket).remove([filePath]);
        return res.status(500).json({ error: error.message });
      }

      return res.status(201).json({ data });
    }

    if (req.method === 'PATCH') {
      const {
        id,
        title,
        description,
        pdfBase64,
        fileName,
        is_published,
        display_order,
      } = req.body || {};

      if (!id) {
        return res.status(400).json({ error: 'id is required.' });
      }

      const { data: existing, error: existingError } = await supabase
        .from(tableName)
        .select('*')
        .eq('id', id)
        .single();

      if (existingError) {
        return res.status(500).json({ error: existingError.message });
      }

      const updatePayload = {};

      if (typeof title === 'string') {
        updatePayload.title = title;
      }

      if (description !== undefined) {
        updatePayload.description = description;
      }

      if (typeof is_published === 'boolean') {
        updatePayload.is_published = is_published;
      }

      if (display_order !== undefined) {
        updatePayload.display_order = display_order;
      }

      let newFilePath = null;

      if (pdfBase64 && fileName) {
        const sanitizedFileName = String(fileName).replace(/[^a-zA-Z0-9._-]/g, '_');
        newFilePath = `${tableName}/${Date.now()}-${sanitizedFileName}`;
        const base64Payload = String(pdfBase64).includes(',')
          ? String(pdfBase64).split(',').pop()
          : String(pdfBase64);
        const pdfBuffer = Buffer.from(base64Payload, 'base64');

        const { error: uploadError } = await supabase.storage
          .from(storageBucket)
          .upload(newFilePath, pdfBuffer, {
            contentType: 'application/pdf',
            upsert: false,
          });

        if (uploadError) {
          return res.status(500).json({ error: uploadError.message });
        }

        const { data: publicUrlData } = supabase.storage
          .from(storageBucket)
          .getPublicUrl(newFilePath);

        updatePayload.pdf_url = publicUrlData?.publicUrl || existing.pdf_url;
      }

      const { data, error } = await supabase
        .from(tableName)
        .update(updatePayload)
        .eq('id', id)
        .select()
        .single();

      if (error) {
        if (newFilePath) {
          await supabase.storage.from(storageBucket).remove([newFilePath]);
        }
        return res.status(500).json({ error: error.message });
      }

      if (newFilePath && existing.pdf_url) {
        const previousPathPrefix = `${supabaseUrl}/storage/v1/object/public/${storageBucket}/`;
        if (existing.pdf_url.startsWith(previousPathPrefix)) {
          const previousPath = existing.pdf_url.replace(previousPathPrefix, '');
          await supabase.storage.from(storageBucket).remove([previousPath]);
        }
      }

      return res.status(200).json({ data });
    }

    if (req.method === 'DELETE') {
      const { id } = req.body || {};

      if (!id) {
        return res.status(400).json({ error: 'id is required.' });
      }

      const { data: existing, error: existingError } = await supabase
        .from(tableName)
        .select('*')
        .eq('id', id)
        .single();

      if (existingError) {
        return res.status(500).json({ error: existingError.message });
      }

      const { error } = await supabase
        .from(tableName)
        .delete()
        .eq('id', id);

      if (error) {
        return res.status(500).json({ error: error.message });
      }

      if (existing?.pdf_url) {
        const filePrefix = `${supabaseUrl}/storage/v1/object/public/${storageBucket}/`;
        if (existing.pdf_url.startsWith(filePrefix)) {
          const filePath = existing.pdf_url.replace(filePrefix, '');
          await supabase.storage.from(storageBucket).remove([filePath]);
        }
      }

      return res.status(200).json({ success: true });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};