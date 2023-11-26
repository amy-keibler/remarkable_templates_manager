use clap::Parser;

mod cli;
mod renderer;
mod template;

use crate::cli::Cli;

fn main() -> eyre::Result<()> {
    color_eyre::install()?;

    let args = Cli::parse();
    println!("args: {args:?}");

    Ok(())
}
