sql.Begin()
sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(64), 'UUID' VARCHAR(96) NOT NULL, 'SteamID' VARCHAR(18) NOT NULL, 'PosX' FLOAT(8) NOT NULL, 'PosY' FLOAT(8) NOT NULL, 'PosZ' FLOAT(8) NOT NULL, 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
sql.Commit()

-- Name (String), this MUST be escaped with sql.SQLStr
-- UUID (String)
-- Owner's SteamID (String)
-- Position (Ints) Vector(300.30, 2234.12, 4.41)
-- Permanent (Boolean)
-- Color (Ints)