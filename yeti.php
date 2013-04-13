<?php
/*
Plugin Name: Yeti YouTube Search
Plugin URI: https://github.com/sagittarian/yeti
Description: Add a YouTube search button to the editor.
Version: 0.1.1
Author: Adam Mesha
Author URI: http://www.mesha.org
Author Email: adam@mesha.org
License: GPL2+
*/

add_action('admin_init', 'yeti_addbutton');
function yeti_addbutton() {
    if ((!current_user_can('edit_posts') && !current_user_can('edit_pages')) || 
            !get_user_option('rich_editing')) {
        return;
    }
    
    add_filter('mce_external_plugins', 'yeti_add_tinymce_plugin');
    add_filter('mce_buttons_2', 'yeti_register_button');
    add_filter('tiny_mce_version', 'yeti_tinymce_increment_version');
    
    wp_enqueue_script('jquery');
    wp_enqueue_script('jquery-ui-dialog');
    wp_enqueue_style('yeti', plugins_url('yeti.css', __FILE__));
}

add_action('admin_enqueue_scripts', 'yeti_add_icon_url');
function yeti_add_icon_url() {
    ?>
    <script type="text/javascript">
    window.yeti_icon = "<?php echo plugins_url('youtube.png', __FILE__); ?>"; 
    </script>
    <?php
}

function yeti_add_tinymce_plugin($plugin_array) {
    $plugin_array['yeti'] = plugins_url('yeti.js', __FILE__);
    return $plugin_array;
}

function yeti_register_button($buttons) {
    array_push($buttons, 'separator', 'yeti');
    return $buttons;
}

function yeti_tinymce_increment_version($version) {
    return ++$version;
}
