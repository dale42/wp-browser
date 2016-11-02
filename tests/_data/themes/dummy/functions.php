<?php

add_action('after_switch_theme', function ($stylesheet) {
    update_option('dummy_after_switch_theme_called', $stylesheet);
});

add_action('switch_theme', function ($stylesheet) {
    update_option('dummy_switch_theme_called', $stylesheet);
});

function dummy_theme_function()
{
    // no-op
}