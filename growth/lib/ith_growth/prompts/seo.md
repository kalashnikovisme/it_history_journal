# SEO Prompt

Project: {{project_name}}
Site URL: {{site_url}}
Website repo: {{website_repo}}
Article URL placeholder: {{article_url}}

Generate SEO improvements for this IT history article.

Article title: {{article_title}}

Return:

- Suggested title improvements (3-5 options)
- Suggested meta description (under 160 characters)
- Suggested Open Graph description
- Suggested schema.org JSON-LD notes
- FAQ block
- Related articles block
- Internal link suggestions
- Hub page suggestions

Article body:

{{article_body}}

---

At the very end of your response, output a machine-readable patch block. You MUST use the tag `seo_patch` (not `json`) and output nothing after the closing fence:

```seo_patch
{
  "title": "the single best title from your suggestions above",
  "excerpt": "the meta description, max 160 characters"
}
```
