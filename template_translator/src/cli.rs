use std::path::PathBuf;

/// Convert a KDL template to a SVG
///
/// Translate a custom template language from KDL to an SVG for use with the Remarkable tablet
#[derive(clap::Parser, Debug)]
#[command(author, version, about, long_about)]
pub struct Cli {
    /// The path to the KDL template
    pub template: PathBuf,

    /// The output file to save the SVG, defaults to <template name>.svg
    #[arg(short, long)]
    pub output_filename: Option<PathBuf>,
}
