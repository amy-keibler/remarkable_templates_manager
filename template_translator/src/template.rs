pub const REMARKABLE_TEMPLATE_WIDTH: u32 = 1404;
pub const REMARKABLE_TEMPLATE_HEIGHT: u32 = 1872;

#[derive(Debug, knuffel::Decode)]
pub struct Template {
    #[knuffel(child, unwrap(argument))]
    pub description: String,
    #[knuffel(child)]
    pub theme: Theme,
}

#[derive(Debug, knuffel::Decode)]
pub struct Theme {
    #[knuffel(child)]
    pub colors: Colors,
    #[knuffel(child)]
    pub font: Font,
}

#[derive(Debug, knuffel::Decode)]
pub struct Colors {
    #[knuffel(child, unwrap(argument))]
    pub primary: String,
    #[knuffel(child, unwrap(argument))]
    pub secondary: String,
    #[knuffel(child, unwrap(argument))]
    pub line: String,
    #[knuffel(child, unwrap(argument))]
    pub border: String,
    #[knuffel(child, unwrap(argument))]
    pub background: String,
}

#[derive(Debug, knuffel::Decode)]
pub struct Font {
    #[knuffel(child, unwrap(argument))]
    pub family: String,
    #[knuffel(child)]
    pub sizes: Sizes,
}

#[derive(Debug, knuffel::Decode)]
pub struct Sizes {
    #[knuffel(child, unwrap(argument))]
    pub header: String,
    #[knuffel(child, unwrap(argument))]
    pub text: String,
}
