# Jekyll Science Kit - Computer Graphics

A comprehensive Jekyll plugin for computer graphics and scientific writing.

## Features

- **Figure Management**: LaTeX-like figure handling with captions and references
- **Bibliography Support**: BibTeX integration with citation management
- **3D Model Viewer**: GLB/GLTF model integration
- **Mathematical Equations**: Numbered equation support with references
- **Alert Blocks**: Bootstrap-style alert components

## Installation

Add this line to your Jekyll site's Gemfile:

```ruby
gem "jekyll-science-kit-computer-graphics"
```

## Usage

### Loading Bibliography
```liquid
{% bibliography_loader _bibliography/references.bib %}
```

### Creating Figures
```liquid
{% figure id="my-figure" size="0.8" caption="My awesome figure" %}
/images/my-image.png
{% endfigure %}
```

### Referencing Figures
```liquid
See {% ref figure:my-figure %} for details.
```

### Citations
```liquid
This work builds on {% cite smith2020 %}.
```

### 3D Model Viewer
```liquid
{% glb_viewer id="model1" models="/assets/models/scene.glb" %}
```

## License

MIT License
