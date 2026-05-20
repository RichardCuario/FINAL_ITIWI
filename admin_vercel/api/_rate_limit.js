const rateLimitStore = globalThis.__itiwiRateLimitStore || new Map();

if (!globalThis.__itiwiRateLimitStore) {
  globalThis.__itiwiRateLimitStore = rateLimitStore;
}

export async function applyRateLimit(req, res, options = {}) {
  const {
    key = 'global',
    windowMs = 60 * 1000,
    max = 10,
    message = 'Too many requests. Please try again later.',
  } = options;

  const now = Date.now();
  const ip = getClientIp(req);
  const bucketKey = `${key}:${ip}`;
  const currentEntry = rateLimitStore.get(bucketKey);

  if (!currentEntry || currentEntry.resetTime <= now) {
    const nextEntry = {
      count: 1,
      resetTime: now + windowMs,
    };

    rateLimitStore.set(bucketKey, nextEntry);
    setRateLimitHeaders(res, {
      limit: max,
      remaining: Math.max(0, max - nextEntry.count),
      resetTime: nextEntry.resetTime,
    });
    pruneExpiredEntries(now);
    return { allowed: true };
  }

  currentEntry.count += 1;
  rateLimitStore.set(bucketKey, currentEntry);

  const remaining = Math.max(0, max - currentEntry.count);
  setRateLimitHeaders(res, {
    limit: max,
    remaining,
    resetTime: currentEntry.resetTime,
  });

  if (currentEntry.count > max) {
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((currentEntry.resetTime - now) / 1000),
    );
    res.setHeader('Retry-After', String(retryAfterSeconds));
    return res.status(429).json({
      error: 'Too many requests.',
      details: message,
      retryAfterSeconds,
    });
  }

  pruneExpiredEntries(now);
  return { allowed: true };
}

function setRateLimitHeaders(res, { limit, remaining, resetTime }) {
  res.setHeader('X-RateLimit-Limit', String(limit));
  res.setHeader('X-RateLimit-Remaining', String(remaining));
  res.setHeader('X-RateLimit-Reset', String(Math.ceil(resetTime / 1000)));
}

function getClientIp(req) {
  const forwardedFor = req.headers['x-forwarded-for'];
  if (typeof forwardedFor === 'string' && forwardedFor.trim()) {
    return forwardedFor.split(',')[0].trim();
  }

  const realIp = req.headers['x-real-ip'];
  if (typeof realIp === 'string' && realIp.trim()) {
    return realIp.trim();
  }

  return req.socket?.remoteAddress || req.connection?.remoteAddress || 'unknown';
}

function pruneExpiredEntries(now) {
  if (rateLimitStore.size <= 500) {
    return;
  }

  for (const [bucketKey, entry] of rateLimitStore.entries()) {
    if (!entry || entry.resetTime <= now) {
      rateLimitStore.delete(bucketKey);
    }
  }
}
