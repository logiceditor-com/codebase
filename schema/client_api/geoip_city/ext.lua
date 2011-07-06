-- TODO: generalize
api:extend_context "pk-webservice.geoip.city" (function()

require 'geoip.city' -- TODO: Hack. This should be handled by apigen.

--------------------------------------------------------------------------------

local geodb = assert(
    geoip.city.open(
        -- TODO: Do not hardcode paths!
        "/usr/local/lib/luarocks/rocks/pk-webservice.geoip.city.data/scm-1"
     .. "/geoip/GeoLiteCity.dat"
      )
  )

return
{
  factory = invariant(geodb); -- a singleton
}

--------------------------------------------------------------------------------

end);
