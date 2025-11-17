-- Add location-based notification columns to todos table
-- Run this in Supabase SQL Editor

ALTER TABLE todos
ADD COLUMN IF NOT EXISTS location_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_name TEXT,
ADD COLUMN IF NOT EXISTS location_radius DOUBLE PRECISION;

-- Add indexes for location queries (optional but recommended for performance)
CREATE INDEX IF NOT EXISTS idx_todos_location ON todos(location_latitude, location_longitude)
WHERE location_latitude IS NOT NULL AND location_longitude IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN todos.location_latitude IS 'Latitude for location-based notifications';
COMMENT ON COLUMN todos.location_longitude IS 'Longitude for location-based notifications';
COMMENT ON COLUMN todos.location_name IS 'Human-readable location name (e.g., Home, Office)';
COMMENT ON COLUMN todos.location_radius IS 'Geofence radius in meters (default: 100m)';
