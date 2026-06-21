# Video Module — IT History Journal

Generates branded short vertical videos (1080×1920) from IT History Journal articles.

## Pipeline

```
Article content.md
  → ScriptGenerator (OpenAI GPT-4.1) → narration.txt
  → AudioGenerator  (OpenAI TTS tts-1-hd, voice: onyx) → narration.mp3
  → ScenePlanner → scenes.json
  → Renderer (Playwright + record.js) → browser-recording.webm
  → FfmpegComposer → final.mp4
```

## Dependencies

All dependencies are bundled in the `video_app` Docker container:

- Ruby 3.3 + gems (`ruby-openai`, `front_matter_parser`, `colorize`)
- Node.js + npm + Playwright (Chromium)
- ffmpeg (for trimming and composing)
- Google Fonts: Inter (loaded at render time)

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | OpenAI API key (set in `.env.dev`) |

## Commands

```bash
# Full pipeline
dip video articles/ru/jun/21/tim_bray_was_born

# Text only (no audio, no render)
dip video text articles/ru/jun/21/tim_bray_was_born

# Render only the calendar segment (no narration, audio, composition, or upload)
dip video part calendar articles/ru/jun/21/tim_bray_was_born

# Audio only (narration text + TTS)
dip audio articles/ru/jun/21/tim_bray_was_born

# Shell in the video container
dip video_shell
```

## Flags

```
--force-text    Regenerate narration.txt even if it already exists
--force-audio   Regenerate narration.mp3 even if it already exists
```

## Output files

Output is written to `video/output/{lang}/{mon}/{dd}/{slug}/`:

| File | Description |
|---|---|
| `prompt.txt` | The full prompt sent to OpenAI |
| `narration.txt` | Generated narration (edit to adjust) |
| `tts-request.json` | TTS API request parameters |
| `narration.mp3` | Audio narration (TTS) |
| `scenes.json` | Scene timing plan |
| `metadata.json` | Article metadata + scene data |
| `render-config.json` | Config for JS renderer |
| `calendar-render-config.json` | Renderer config for the standalone calendar segment |
| `browser-recording.webm` | Trimmed browser recording |
| `calendar.webm` | Standalone calendar segment rendered by `dip video part calendar` |
| `final.mp4` | Final composed video |

## Editing the narration

```bash
# Generate just the narration text
dip video text articles/ru/jun/21/tim_bray_was_born

# Edit video/output/ru/jun/21/tim_bray_was_born/narration.txt
# Then re-generate audio and video
dip audio articles/ru/jun/21/tim_bray_was_born
dip video articles/ru/jun/21/tim_bray_was_born
```

The `--force-audio` flag forces TTS regeneration even if `narration.mp3` exists.
`final.mp4` is always overwritten.

## Directory structure

```
video/
  bin/
    video          # Full pipeline and text-only entrypoint
    audio          # Audio-only entrypoint
  lib/
    video.rb       # Main require file
    video/
      article_loader.rb    # Parse article content.md
      output_paths.rb      # Output file paths
      openai_client.rb     # OpenAI wrapper (chat + TTS)
      script_generator.rb  # Narration text via GPT-4.1
      audio_generator.rb   # TTS via tts-1-hd
      scene_planner.rb     # Scene timing calculation
      renderer.rb          # Calls record.js via Node
      ffmpeg_composer.rb   # Combines webm + mp3 → mp4
  renderer/
    index.html       # 1080×1920 page loaded by Playwright
    record.js        # Playwright recording script
    package.json     # Playwright dependency
    src/
      styles.css         # Dark theme CSS
      webgl_background.js  # Particle field (WebGL)
      calendar.js        # Calendar scene
      cover_scene.js     # Cover + title card scenes
      facts_scene.js     # Fact text overlay
      cta_scene.js       # Final CTA screen
      main.js            # Animation orchestrator
  output/
    .gitkeep
  Gemfile
  README.md
```

## Troubleshooting

**`OPENAI_API_KEY is not set`** — Add `OPENAI_API_KEY=sk-...` to `.env.dev`.

**`node is not available`** — Run `dip video_shell` and check `node --version`. Rebuild the video container: `dip compose build video_app`.

**`ffmpeg not found`** — Same as above; check `ffmpeg -version` inside the container.

**`record.js failed`** — Run `dip video_shell`, then run record.js manually with `--headful` disabled (headful won't work in Docker). Check `browser` console output in the ruby logs.

**Fonts appear as boxes** — The renderer fetches Inter from Google Fonts at render time. Ensure the container has internet access or pre-install the fonts in the Dockerfile.
