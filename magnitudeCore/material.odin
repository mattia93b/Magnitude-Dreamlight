package magnitudeCore

// logger
import "core:log"
// math
import "core:math/linalg"

Material::struct #align(16){
    ambient: linalg.Vector4f32,
    diffuse: linalg.Vector4f32,
    specular: linalg.Vector4f32,
    shininess: f32,
	_pad0:[3]f32,
}
	
createMaterial::proc(materialAmbient:linalg.Vector3f32, materialDiffuse: linalg.Vector3f32, materialSpecular: linalg.Vector3f32, materialShininess:f32) -> Material{
	
	material: Material;

	material.ambient = {materialAmbient.x, materialAmbient.y, materialAmbient.z, 0.0};
	material.diffuse = {materialDiffuse.x, materialDiffuse.y, materialDiffuse.z, 0.0};
	material.specular = {materialSpecular.x, materialSpecular.y, materialSpecular.z, 0.0};
	material.shininess = materialShininess;

	return material
}

emerald::proc() -> Material {
	return Material{{0.0215, 0.1745, 0.0215, 0.0}, {0.07568, 0.61424, 0.07568, 0.0}, {0.633, 0.727811, 0.633, 0.0}, 0.6,{0.0,0.0,0.0}};
}

jade::proc() -> Material {
	return Material{{0.135, 0.2225, 0.1575, 0.0}, {0.54, 0.89, 0.63, 0.0}, {0.316228, 0.316228, 0.316228, 0.0}, 0.1,{0.0,0.0,0.0}};
}

obsidian::proc() -> Material{
	return Material{{0.05375, 0.05, 0.06625, 0.0}, {0.18275, 0.17, 0.22525, 0.0}, {0.332741, 0.328634, 0.346435, 0.0}, 0.3,{0.0,0.0,0.0}};
}

pearl::proc() -> Material{
	return Material{{0.25, 0.20725, 0.20725, 0.0}, {1, 0.829, 0.829, 0.0}, {0.296648, 0.296648, 0.296648, 0.0}, 0.088,{0.0,0.0,0.0}};
}

ruby::proc() -> Material{
	return Material{{0.1745, 0.01175, 0.01175, 0.0}, {0.61424, 0.04136, 0.04136, 0.0}, {0.727811, 0.626959, 0.626959, 0.0}, 0.6,{0.0,0.0,0.0}};
}

turquoise::proc() -> Material{
	return Material{{0.1, 0.18725, 0.1745, 0.0}, {0.396, 0.74151, 0.69102, 0.0}, {0.297254, 0.30829, 0.306678, 0.0}, 0.1,{0.0,0.0,0.0}};
}

brass::proc() -> Material{
	return Material{{0.329412, 0.223529, 0.027451, 0.0}, {0.780392, 0.568627, 0.113725, 0.0}, {0.992157, 0.941176, 0.807843, 0.0}, 0.21794872,{0.0,0.0,0.0}};
}

bronze::proc() -> Material{
	return Material{{0.2125, 0.1275, 0.054, 0.0}, {0.714, 0.4284, 0.18144, 0.0}, {0.393548, 0.271906, 0.166721, 0.0}, 0.2,{0.0,0.0,0.0}};
}

chrome::proc() -> Material{
	return Material{{0.25, 0.25, 0.25, 0.0}, {0.4, 0.4, 0.4, 0.0}, {0.774597, 0.774597, 0.774597, 0.0}, 0.6,{0.0,0.0,0.0}};
}

copper::proc() -> Material{
	return Material{{0.19125, 0.0735, 0.0225, 0.0}, {0.7038, 0.27048, 0.0828, 0.0}, {0.256777, 0.137622, 0.086014, 0.0}, 0.1,{0.0,0.0,0.0}};
}

gold::proc() -> Material{
	return Material{{0.24725, 0.1995, 0.0745, 0.0}, {0.75164, 0.60648, 0.22648, 0.0}, {0.628281,	0.555802, 0.366065, 0.0}, 0.4,{0.0,0.0,0.0}};
}

silver::proc() -> Material{
	return Material{{0.19225, 0.19225, 0.19225, 0.0}, {0.50754, 0.50754, 0.50754, 0.0}, {0.508273, 0.508273, 0.508273, 0.0}, 0.4,{0.0,0.0,0.0}};
}

blackPlastic::proc() -> Material{
	return Material{{0.0, 0.0, 0.0, 0.0}, {0.01, 0.01, 0.01, 0.0}, {0.50, 0.50, 0.50, 0.0}, 0.25,{0.0,0.0,0.0}};
}

cyanPlastic::proc() -> Material{
	return Material{{0.0, 0.1, 0.06, 0.0}, {0.0, 0.50980392, 0.50980392, 0.0}, {0.50196078, 0.50196078, 0.50196078, 0.0}, 0.25,{0.0,0.0,0.0}};
}

greenPlastic::proc() -> Material{
	return Material{{0.0, 0.0, 0.0, 0.0}, {0.1, 0.35, 0.1, 0.0}, {0.45, 0.55, 0.45, 0.0}, 0.25,{0.0,0.0,0.0}};
}

redPlastic::proc() -> Material{
	return Material{{0.0, 0.0, 0.0, 0.0}, {0.5, 0.0, 0.0, 0.0}, {0.7, 0.6, 0.6, 0.0}, 0.25,{0.0,0.0,0.0}};
}

whitePlastic::proc() -> Material{
	return Material{{0.0, 0.0, 0.0, 0.0}, {0.55, 0.55, 0.55, 0.0}, {0.70, 0.70, 0.70, 0.0}, 0.25,{0.0,0.0,0.0}};
}

yellowPlastic::proc() -> Material{
	return Material{{0.0, 0.0, 0.0, 0.0}, {0.5, 0.5, 0.0, 0.0}, {0.60, 0.60, 0.50, 0.0}, 0.25,{0.0,0.0,0.0}};
}

blackRubber::proc() -> Material{
	return Material{{0.02, 0.02, 0.02, 0.0}, {0.01, 0.01, 0.01, 0.0}, {0.4, 0.4, 0.4, 0.0}, 0.078125,{0.0,0.0,0.0}};
}

cyanRubber::proc() -> Material{
	return Material{{0.0, 0.05, 0.05, 0.0}, {0.4, 0.5, 0.5, 0.0}, {0.04, 0.7, 0.7, 0.0}, 0.078125,{0.0,0.0,0.0}};
}

greenRubber::proc() -> Material{
	return Material{{0.0, 0.05, 0.0, 0.0}, {0.4, 0.5, 0.4, 0.0}, {0.04, 0.7, 0.04, 0.0}, 0.078125,{0.0,0.0,0.0}};
}

redRubber::proc() -> Material{
	return Material{{0.05, 0.0, 0.0, 0.0}, {0.5, 0.4, 0.4, 0.0}, {0.7, 0.04, 0.04, 0.0}, 0.078125,{0.0,0.0,0.0}};
}

whiteRubber::proc() -> Material{
	return Material{{0.05, 0.05, 0.05, 0.0}, {0.5, 0.5, 0.5, 0.0}, {0.7, 0.7, 0.7, 0.0}, 0.078125,{0.0,0.0,0.0}};
}

yellowRubber::proc() -> Material{
	return Material{{0.05, 0.05, 0.0, 0.0}, {0.5, 0.5, 0.4, 0.0}, {0.7, 0.7, 0.04, 0.0}, 0.078125,{0.0,0.0,0.0}};
}