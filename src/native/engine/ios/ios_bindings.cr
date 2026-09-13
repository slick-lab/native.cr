# src/native/engine/ios/ios_bindings.cr
#
# LibIOS — the C ABI contract between Crystal framework code and the
# future iOS runtime (libnative_ios, a Swift/ObjC dylib exporting these
# symbols). Every fun here was derived from actual framework call sites,
# so implementing this header on the Swift side makes the whole iOS
# branch come alive.
#
# ── ABI conventions ──────────────────────────────────────────────────────────
#
#   Handles       int64        Opaque view/service handles; 0 = invalid.
#   Strings       uint8*       Borrowed UTF-8, NUL-terminated. Returned
#                              strings are owned by the CALLER and must be
#                              released via free_string / free_string_array /
#                              free. Passed strings are owned by the CALLEE
#                              and must be copied if retained.
#   Booleans      bool         C _Bool (Crystal's Bool maps 1:1).
#   Colors        float ×3/4   Normalized 0.0–1.0 components (RGBA).
#   Nullable str  uint8*       NULL means "absent" (e.g. share attachments).
#   Threading                  All callbacks fire on the MAIN thread (see
#                              PushManager.java for the Android equivalent).
#
# NOTE: `create_animator` is deliberately zero-arg to match today's call
# sites — the animation start/end values currently have no iOS channel.
# Extend the ABI (not the call sites) when animating values on iOS.

@[Link("native_ios")]
lib LibIOS
  # ── Memory (for strings returned by this library) ──────────────────────────
  fun free(ptr : Void*) : Void
  fun free_string(str : UInt8*) : Void
  fun free_string_array(arr : UInt8**) : Void

  # ── Platform / device ───────────────────────────────────────────────────────
  fun get_device_model : UInt8*
  fun get_os_version : UInt8*
  fun get_screen_width : Int32
  fun get_screen_height : Int32
  fun get_screen_density : Float32
  fun get_battery_level : Int32
  fun is_charging : Bool
  fun vibrate : Void
  fun open_url(url : UInt8*) : Bool
  fun show_toast(text : UInt8*, duration : Float64) : Void
  fun open_settings : Void
  fun share(text : UInt8*, url : UInt8*, title : UInt8*,
            image_path : UInt8*, image_data : UInt8*, mime_type : UInt8*) : Void
  fun copy_to_clipboard(text : UInt8*) : Void
  fun paste_from_clipboard : UInt8*

  # ── System clipboard (direct) ───────────────────────────────────────────────
  fun clipboard_set_text(text : UInt8*) : Void
  fun clipboard_get_text : UInt8*
  fun clipboard_has_text : Bool

  # ── Permissions ─────────────────────────────────────────────────────────────
  fun check_permission(type : Int32) : Int32
  fun request_permission(type : Int32) : Void

  # ── View base ───────────────────────────────────────────────────────────────
  fun view_set_position(handle : Int64, x : Int32, y : Int32) : Void
  fun view_set_size(handle : Int64, width : Int32, height : Int32) : Void
  fun view_set_visible(handle : Int64, visible : Bool) : Void
  fun view_set_enabled(handle : Int64, enabled : Bool) : Void
  fun view_set_tag(handle : Int64, tag : UInt8*) : Void
  fun view_set_background_color(handle : Int64, r : Float32, g : Float32,
                                b : Float32, a : Float32) : Void

  # ── Widget factories ────────────────────────────────────────────────────────
  fun create_button : Void*
  fun create_label : Void*
  fun create_checkbox : Void*
  fun create_switch : Void*
  fun create_radio_button : Void*
  fun create_text_field : Void*
  fun create_image_view : Void*
  fun create_progress_view : Void*
  fun create_slider : Void*
  fun create_card_view : Void*
  fun create_stack_view : Void*
  fun create_scroll_view : Void*
  fun create_table_view : Void*
  fun create_picker_view : Void*
  fun create_web_view : Void*
  fun create_navigation_bar : Void*
  fun create_alert_controller : Void*
  fun create_animator : Void*
  fun create_animator_set : Void*
  fun create_camera_controller : Void*
  fun create_video_player : Void*

  # ── Label ───────────────────────────────────────────────────────────────────
  fun label_set_text(handle : Int64, text : UInt8*) : Void
  fun label_set_text_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun label_set_text_size(handle : Int64, size : Int32) : Void
  fun label_set_font(handle : Int64, font : UInt8*) : Void
  fun label_set_max_lines(handle : Int64, lines : Int32) : Void

  # ── Button ──────────────────────────────────────────────────────────────────
  fun button_set_text(handle : Int64, text : UInt8*) : Void
  fun button_set_text_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun button_set_text_size(handle : Int64, size : Int32) : Void
  fun button_set_background_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void

  # ── Checkbox ────────────────────────────────────────────────────────────────
  fun checkbox_set_text(handle : Int64, text : UInt8*) : Void
  fun checkbox_set_checked(handle : Int64, checked : Bool) : Void
  fun checkbox_is_checked(handle : Int64) : Bool
  fun checkbox_set_text_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun checkbox_set_text_size(handle : Int64, size : Int32) : Void

  # ── Radio button ────────────────────────────────────────────────────────────
  fun radio_button_set_text(handle : Int64, text : UInt8*) : Void
  fun radio_button_set_checked(handle : Int64, checked : Bool) : Void
  fun radio_button_is_checked(handle : Int64) : Bool
  fun radio_button_set_text_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun radio_button_set_text_size(handle : Int64, size : Int32) : Void

  # ── Switch ──────────────────────────────────────────────────────────────────
  fun switch_set_on(handle : Int64, on : Bool) : Void
  fun switch_is_on(handle : Int64) : Bool

  # ── Text field ──────────────────────────────────────────────────────────────
  fun text_field_set_text(handle : Int64, text : UInt8*) : Void
  fun text_field_set_placeholder(handle : Int64, text : UInt8*) : Void
  fun text_field_set_text_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun text_field_set_text_size(handle : Int64, size : Int32) : Void
  fun text_field_set_input_type(handle : Int64, input_type : Int32) : Void
  fun text_field_get_text(handle : Int64) : UInt8*

  # ── Progress view ───────────────────────────────────────────────────────────
  fun progress_view_set_progress(handle : Int64, progress : Int32, max : Int32) : Void
  fun progress_view_set_max(handle : Int64, max : Int32) : Void
  fun progress_view_set_indeterminate(handle : Int64, indeterminate : Bool) : Void

  # ── Slider ──────────────────────────────────────────────────────────────────
  fun slider_set_value(handle : Int64, value : Int32, max : Int32) : Void
  fun slider_set_max(handle : Int64, max : Int32) : Void
  fun slider_get_value(handle : Int64) : Float32

  # ── Image view ──────────────────────────────────────────────────────────────
  fun image_view_set_resource(handle : Int64, resource_id : Int32) : Void
  fun image_view_set_path(handle : Int64, path : UInt8*) : Void
  fun image_view_set_data(handle : Int64, data : UInt8*, size : Int32) : Void
  fun image_view_set_scale_type(handle : Int64, scale_type : Int32) : Void
  fun image_view_set_alpha(handle : Int64, alpha : Float32) : Void

  # ── Card view ───────────────────────────────────────────────────────────────
  fun card_view_add_subview(handle : Int64, child : Int64) : Void
  fun card_view_remove_subview(handle : Int64, child : Int64) : Void
  fun card_view_set_background_color(handle : Int64, r : Float32, g : Float32, b : Float32) : Void
  fun card_view_set_radius(handle : Int64, radius : Float32) : Void
  fun card_view_set_elevation(handle : Int64, elevation : Float32) : Void

  # ── Stack view (linear layout) ──────────────────────────────────────────────
  fun stack_view_add_view(handle : Int64, child : Int64) : Void
  fun stack_view_remove_view(handle : Int64, child : Int64) : Void
  fun stack_view_remove_all_views(handle : Int64) : Void
  fun stack_view_set_axis(handle : Int64, axis : Int32) : Void
  fun stack_view_set_padding(handle : Int64, left : Int32, top : Int32,
                             right : Int32, bottom : Int32) : Void

  # ── Scroll view ─────────────────────────────────────────────────────────────
  fun scroll_view_add_view(handle : Int64, child : Int64) : Void
  fun scroll_view_remove_view(handle : Int64, child : Int64) : Void
  fun scroll_view_scroll_to(handle : Int64, x : Int32, y : Int32, animated : Bool) : Void
  fun scroll_view_scroll_to_bottom(handle : Int64, animated : Bool) : Void
  fun scroll_view_get_scroll_x(handle : Int64) : Int32
  fun scroll_view_get_scroll_y(handle : Int64) : Int32
  fun scroll_view_set_direction(handle : Int64, direction : Int32) : Void

  # ── Table view (recycler view) ──────────────────────────────────────────────
  fun table_view_reload_data(handle : Int64) : Void
  fun table_view_scroll_to_row(handle : Int64, position : Int32, smooth : Bool) : Void
  fun table_view_set_delegate(handle : Int64, delegate : Int64) : Void
  fun table_view_set_style(handle : Int64, style : Int32) : Void

  # ── Picker view (spinner) ───────────────────────────────────────────────────
  fun picker_view_set_items(handle : Int64, items : UInt8*) : Void
  fun picker_view_set_selected(handle : Int64, index : Int32) : Void
  fun picker_view_get_selected(handle : Int64) : Int32

  # ── Web view ────────────────────────────────────────────────────────────────
  fun web_view_load_url(handle : Int64, url : UInt8*) : Void
  fun web_view_load_html(handle : Int64, html : UInt8*, base_url : UInt8*) : Void
  fun web_view_set_js_enabled(handle : Int64, enabled : Bool) : Void
  fun web_view_can_go_back(handle : Int64) : Bool
  fun web_view_can_go_forward(handle : Int64) : Bool
  fun web_view_go_back(handle : Int64) : Void
  fun web_view_go_forward(handle : Int64) : Void
  fun web_view_reload(handle : Int64) : Void
  fun web_view_stop_loading(handle : Int64) : Void

  # ── Navigation bar (toolbar) ────────────────────────────────────────────────
  fun navigation_bar_set_title(handle : Int64, title : UInt8*) : Void

  # ── Alert controller ────────────────────────────────────────────────────────
  fun alert_set_title(handle : Int64, title : UInt8*) : Void
  fun alert_set_message(handle : Int64, message : UInt8*) : Void
  fun alert_add_action(handle : Int64, title : UInt8*, style : Int32) : Void
  fun alert_show(handle : Int64) : Void
  fun alert_dismiss(handle : Int64) : Void

  # ── Animator ────────────────────────────────────────────────────────────────
  fun animator_start(handle : Int64) : Void
  fun animator_cancel(handle : Int64) : Void
  fun animator_set_duration(handle : Int64, duration : Int32) : Void
  fun animator_set_repeat_count(handle : Int64, count : Int32) : Void
  fun animator_set_play_sequentially(handle : Int64) : Void
  fun animator_set_start(handle : Int64) : Void

  # ── Video player ────────────────────────────────────────────────────────────
  fun video_player_load(handle : Int64, path : UInt8*) : Void
  fun video_player_play(handle : Int64) : Void
  fun video_player_pause(handle : Int64) : Void
  fun video_player_stop(handle : Int64) : Void
  fun video_player_seek_to(handle : Int64, position : Int32) : Void
  fun video_player_set_looping(handle : Int64, looping : Bool) : Void
  fun video_player_set_volume(handle : Int64, volume : Float32) : Void
  fun video_player_set_scale_type(handle : Int64, scale_type : Int32) : Void
  fun video_player_current_position(handle : Int64) : Int32
  fun video_player_duration(handle : Int64) : Int32

  # ── Camera ──────────────────────────────────────────────────────────────────
  fun camera_start_preview(handle : Int64) : Void
  fun camera_stop_preview(handle : Int64) : Void
  fun camera_take_photo(handle : Int64) : Void
  fun camera_start_recording(handle : Int64) : Void
  fun camera_stop_recording(handle : Int64) : Void
  fun camera_set_facing(handle : Int64, facing : Int32) : Void
  fun camera_set_flash_mode(handle : Int64, mode : Int32) : Void

  # ── Audio: sound effects ────────────────────────────────────────────────────
  fun sound_load(path : UInt8*) : Void*
  fun sound_play(handle : Int64, volume : Float32, looping : Bool,
                 pitch : Float32, pan : Float32) : Void*
  fun sound_unload(handle : Int64) : Void
  fun sound_stop_all(handle : Int64) : Void
  fun sound_instance_stop(instance : Int64) : Void
  fun sound_instance_pause(instance : Int64) : Void
  fun sound_instance_resume(instance : Int64) : Void
  fun sound_instance_set_volume(instance : Int64, volume : Float32) : Void
  fun sound_instance_is_playing(instance : Int64) : Bool
  fun stop_all_sounds : Void
  fun pause_all_sounds : Void
  fun resume_all_sounds : Void
  fun set_master_volume(volume : Float32) : Void
  fun set_sfx_volume(volume : Float32) : Void

  # ── Audio: music ────────────────────────────────────────────────────────────
  fun music_load(path : UInt8*) : Void*
  fun music_play(handle : Int64, looping : Bool) : Void
  fun music_pause(handle : Int64) : Void
  fun music_resume(handle : Int64) : Void
  fun music_stop(handle : Int64) : Void
  fun music_unload(handle : Int64) : Void
  fun music_seek(handle : Int64, position : Float64) : Void
  fun music_get_position(handle : Int64) : Float64
  fun music_get_duration(handle : Int64) : Float64
  fun music_set_volume(handle : Int64, volume : Float32) : Void
  fun stop_music : Void
  fun pause_music : Void
  fun resume_music : Void
  fun set_music_volume(volume : Float32) : Void

  # ── Audio: recorder ─────────────────────────────────────────────────────────
  fun recorder_start : Void*
  fun recorder_stop(handle : Int64, size : Int32*) : UInt8*

  # ── Connectivity ────────────────────────────────────────────────────────────
  fun connectivity_get_info : UInt8*
  fun connectivity_start_monitoring : Void
  fun connectivity_stop_monitoring : Void

  # ── HTTP ────────────────────────────────────────────────────────────────────
  fun http_request(url : UInt8*, method : UInt8*, headers_json : UInt8*,
                   body : UInt8*, timeout : Float64) : UInt8*
  fun http_request_stream(url : UInt8*, method : UInt8*, headers_json : UInt8*,
                          body : UInt8*, timeout : Float64) : Void

  # ── WebSocket ───────────────────────────────────────────────────────────────
  fun websocket_connect(url : UInt8*) : Void
  fun websocket_send_text(text : UInt8*) : Void
  fun websocket_send_binary(data : UInt8*, size : Int32) : Void
  fun websocket_close : Void

  # ── Storage (documents/cache/bundle via the type discriminator) ─────────────
  fun file_write(path : UInt8*, data : UInt8*, size : Int32, type : Int32) : Bool
  fun file_read(path : UInt8*, size : Int32*, type : Int32) : UInt8*
  fun file_exists(path : UInt8*, type : Int32) : Bool
  fun file_delete(path : UInt8*, type : Int32) : Bool
  fun file_list(directory : UInt8*, type : Int32) : UInt8**

  # ── User defaults (key-value storage) ───────────────────────────────────────
  fun user_defaults_get(key : UInt8*) : UInt8*
  fun user_defaults_set(key : UInt8*, value : UInt8*) : Void
  fun user_defaults_delete(key : UInt8*) : Void
  fun user_defaults_contains(key : UInt8*) : Bool
  fun user_defaults_clear : Void
  fun user_defaults_all_keys : UInt8**

  # ── Notifications (local + scheduled) ───────────────────────────────────────
  fun notification_init : Void
  fun notification_permission_granted : Bool
  fun request_notification_permission : Bool
  fun show_notification(id : Int32, title : UInt8*, body : UInt8*,
                        badge_number : Int32, sound : UInt8*, payload : UInt8*) : Bool
  fun schedule_notification(id : Int32, title : UInt8*, body : UInt8*,
                            trigger_time : Float64, repeats : Bool, payload : UInt8*) : Bool
  fun cancel_notification(id : Int32) : Void
  fun cancel_all_notifications : Void
  fun set_badge_number(count : Int32) : Void

  # ── Push (APNs bridge is delivered via notification callbacks; see
  #    push_notifications.cr — the token arrives through the same channel) ────

  # ── In-app purchase ─────────────────────────────────────────────────────────
  fun payment_init(merchant_id : UInt8*) : Void
  fun payment_purchase(product_id : UInt8*) : Void
  fun payment_restore : Void
  fun payment_is_purchased(product_id : UInt8*) : Bool
  fun payment_is_subscription_active(product_id : UInt8*) : Bool
  fun payment_fetch_products(product_ids_json : UInt8*) : UInt8*

  # ── Biometric ───────────────────────────────────────────────────────────────
  fun is_biometric_enrolled : Bool
  fun get_biometric_type : Int32
  fun authenticate_biometric(title : UInt8*, subtitle : UInt8*, description : UInt8*,
                             cancel_title : UInt8*, fallback_title : UInt8*,
                             allow_fallback : Bool) : Int32

  # ── Location ────────────────────────────────────────────────────────────────
  fun location_start_updates(accuracy : Int32, min_distance : Float32, min_time : Int64) : Void
  fun location_stop_updates : Void
  fun location_get_last : UInt8*

  # ── Sensors ─────────────────────────────────────────────────────────────────
  fun sensor_manager_init : Int64
  fun sensor_available(type : Int32) : Bool
  fun sensor_start(type : Int32, delay_us : Int32) : Void
  fun sensor_stop(type : Int32) : Void

  # ── Image picker ────────────────────────────────────────────────────────────
  fun image_picker_pick(source : Int32, quality : Int32,
                        max_width : Int32, max_height : Int32) : Void
  fun image_picker_take_photo(quality : Int32, max_width : Int32, max_height : Int32) : Void
end

# ── String extension ────────────────────────────────────────────────────────────
# The iOS branches pass strings as C UTF-8 via `.to_utf8`. It mirrors
# `to_unsafe` but keeps the intent explicit at call sites: a borrowed,
# NUL-terminated UTF-8 pointer handed to the iOS dylib.
class String
  def to_utf8 : UInt8*
    to_unsafe
  end
end
