use svg::Document;

use crate::template::{Template, REMARKABLE_TEMPLATE_HEIGHT, REMARKABLE_TEMPLATE_WIDTH};
use std::path::PathBuf;

pub fn render(template: &Template, output: PathBuf) -> eyre::Result<()> {
    let document = Document::new()
        .set("width", format!("{REMARKABLE_TEMPLATE_WIDTH}px"))
        .set("height", format!("{REMARKABLE_TEMPLATE_HEIGHT}px"))
        .set("baseProfile", "tiny")
        .set(
            "viewBox",
            (0, 0, REMARKABLE_TEMPLATE_WIDTH, REMARKABLE_TEMPLATE_HEIGHT),
        );

    svg::save(output, &document)?;
    Ok(())
}
