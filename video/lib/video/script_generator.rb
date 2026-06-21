require "fileutils"

module Video
  class ScriptGenerator
    def initialize(article_info, output_paths, openai_client)
      @info    = article_info
      @paths   = output_paths
      @client  = openai_client
    end

    # Returns narration text.
    # Skips generation if narration.txt already exists unless force: true.
    def generate(force: false)
      @paths.ensure_dir!

      if File.exist?(@paths.narration_txt) && !force
        return File.read(@paths.narration_txt)
      end

      prompt = build_prompt
      File.write(@paths.prompt_txt, prompt)

      messages = [
        { role: "system", content: system_prompt },
        { role: "user",   content: prompt }
      ]

      narration = @client.chat(messages: messages, model: "gpt-4.1", temperature: 0.75)
      narration = narration.strip

      File.write(@paths.narration_txt, narration)
      narration
    end

    private

    def system_prompt
      <<~PROMPT.strip
        You are a documentary narrator for IT History Journal — a publication about moments
        that shaped the history of computing and technology.

        Write narrations that are calm, documentary, slightly cinematic.
        Do NOT use podcast-intro energy ("Hey everyone!").
        Do NOT say "like and subscribe", "subscribe", "follow us" in the middle of narration.
        Do NOT use clichés like "changed the world forever", "revolutionized everything", "would never be the same".
        Start straight from the hook — no preamble.
        Output ONLY the narration text. No stage directions, no speaker labels, no markdown.
      PROMPT
    end

    def build_prompt
      lang        = @info[:lang]
      title       = @info[:title]
      date_str    = @info[:date_display]
      content_md  = @info[:content_md]

      word_target = lang == "ru" ? "100–130 words" : "120–150 words"
      cta = lang == "ru" ? "Подписывайтесь на IT History Journal." : "Follow IT History Journal."

      lang_instruction = if lang == "ru"
        "Write the narration in Russian."
      else
        "Write the narration in English."
      end

      <<~PROMPT.strip
        #{lang_instruction}

        Article title: #{title}
        Date: #{date_str}

        Article content:
        #{content_md}

        ---

        Write a short historical documentary narration (#{word_target}) for a vertical short video.

        Structure:
        1. Hook — grab attention immediately with the most compelling fact or image
        2. Date + Event — state what happened and when
        3. What happened — the key event in a sentence or two
        4. Why it mattered — the significance
        5. What came after — brief legacy
        6. Soft CTA — end with exactly this line: "#{cta}"

        Requirements:
        - #{word_target} total
        - Calm, documentary tone
        - No H1/H2 headings, no bullet points, no markdown
        - No stage directions or speaker labels
        - Start immediately with the hook sentence
        - End with: #{cta}
      PROMPT
    end
  end
end
