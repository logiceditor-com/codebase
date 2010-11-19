function assert(cond, msg)
{
  if (cond)
  {
    return cond
  }
  CRITICAL_ERROR("Assertion failed: " + String(msg))
  return undefined
}
