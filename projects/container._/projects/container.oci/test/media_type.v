namespace container.oci;

[test]
micro test_media_type_layer_classifier() -> unit {
    if !oci_media_type_is_layer(oci_media_type_layer_tar()) {
        panic("tar layer must be a layer")
    }
    if !oci_media_type_is_layer(oci_media_type_layer_tar_gzip()) {
        panic("tar+gzip layer must be a layer")
    }
    if !oci_media_type_is_layer(docker_media_type_layer_tar_gzip()) {
        panic("docker rootfs gzip must be a layer")
    }
    if oci_media_type_is_layer(oci_media_type_image_config()) {
        panic("config is not a layer")
    }
}

[test]
micro test_media_type_manifest_and_config_classifier() -> unit {
    if !oci_media_type_is_manifest_family(oci_media_type_image_manifest()) {
        panic("oci manifest must be manifest family")
    }
    if !oci_media_type_is_manifest_family(docker_media_type_manifest_v2()) {
        panic("docker v2 manifest must be manifest family")
    }
    if !oci_media_type_is_config_family(oci_media_type_image_config()) {
        panic("oci config must be config family")
    }
    if oci_media_type_is_config_family(oci_media_type_image_manifest()) {
        panic("manifest is not config")
    }
}

[test]
micro test_media_type_constants_are_stable_strings() -> unit {
    if oci_media_type_image_index().length() == 0 {
        panic("media type constants must be non-empty")
    }
    if oci_media_type_image_index() == oci_media_type_image_manifest() {
        panic("distinct media types must differ")
    }
}
