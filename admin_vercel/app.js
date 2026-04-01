import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://jbhlbukxankrtcwhqoll.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc'
)

async function addHotline() {
  const { data, error } = await supabase
    .from('hotlines')
    .insert([
      {
        name: "MDRRMO",
        description: "Municipal Risk Reduction Office",
        category: "Emergency",
        phone_numbers: ["09178613176"]
      }
    ])

  if (error) {
    console.log("Error:", error)
  } else {
    console.log("Inserted:", data)
  }
}

addHotline()