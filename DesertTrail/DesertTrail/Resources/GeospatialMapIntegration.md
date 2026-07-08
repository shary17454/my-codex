# Geospatial Map Integration

This app supports high-quality wilderness map sources through a source-first workflow:

1. Verify licensing and source authority before bundling or downloading any map.
2. Prefer official WMS/WMTS/GeoJSON/MBTiles services for dynamic GIS layers.
3. Use PDFKit for licensed high-resolution PDF sheets such as Ajaji maps and marked plans.
4. Convert raster map sheets to WGS84-aligned tiles before using them as MapKit overlays.
5. Store imported maps in Application Support with complete file protection.
6. Build a local search index for wadis, reefs, plateaus, roads, and named landmarks.

Primary source categories:

- Saudi Geological Survey official portal for geological and terrain map references: https://sgs.gov.sa
- Ajaji Maps licensed PDFs or user-provided official map files: https://ajajimaps.com
- Licensed WMTS or MBTiles packages for offline wilderness areas.

Current bundled PDFs are development samples generated from user-provided images. Replace them from the in-app source manager when official licensed PDFs are available.
