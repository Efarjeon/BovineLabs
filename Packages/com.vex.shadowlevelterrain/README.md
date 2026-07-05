# Shadow Level Terrain

Self-contained Unity package containing the **Terrain2** prefab from the
Shadow level, with all of its terrain data, terrain layer, and texture bundled.
No other packages required.

## What is included

```text
Prefabs/Terrain (Shadow)/Terrain2.prefab     <- the prefab
Shadow Terrain/Shadow2.asset                <- TerrainData (heightmap + splatmap)
Shadow Terrain/Shadow1.terrainlayer         <- terrain layer asset
Shadow Terrain/1 (5).png                    <- layer splat texture
```

All original `.meta` files (with their GUIDs) are preserved so the
prefab-to-TerrainData references inside the .prefab keep resolving.

## Install

In the consumer project's `Packages/manifest.json`:

```json
"com.vex.shadowlevelterrain": "https://github.com/NIbir888/Shadow-Level-Terrain.git"
```

Drop `Terrain2.prefab` into any scene and it loads with its data + texture.

## What is NOT included (Unity-shipped)

These are part of every URP / core install and don't need to be bundled:

```text
Packages/com.unity.render-pipelines.universal/...
Packages/com.unity.render-pipelines.core/...
Packages/com.unity.shadergraph/...
Library/unity default resources
```

## License

Internal package, redistribution at your own discretion.
