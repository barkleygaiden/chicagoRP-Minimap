sql.Begin()
sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(64), 'PosX' INT(8) NOT NULL, 'PosY' INT(8) NOT NULL, 'PosZ' INT(8) NOT NULL, 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
sql.Commit()

-- Name (String), this MUST be escaped with sql.SQLStr
-- Position (Ints) Vector(300.30, 2234.12, 4.41)
-- Permanent (Boolean)
-- Color (Ints)