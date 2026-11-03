# This file is used to generate the encrypted configuration file based on json structure.

from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import base64

# Key (256-bit / 32 bytes) and IV (128-bit / 16 bytes)
KEY = bytes.fromhex("93bcead916b779be26d69fb61a33d9a7f51c027805f46bda71a94bcf00000000")
IV  = bytes.fromhex("47ae599c354da66c2fa14abfc87b126a")

def encrypt(plaintext: str) -> dict:
    # Step 1: Convert string to Base64
    base64_str = base64.b64encode(plaintext.encode('utf-8')).decode('utf-8')
    print(f"Step 1 - Base64     : {base64_str}")

    # Step 2: Encrypt the Base64 string using AES CBC
    cipher = AES.new(KEY, AES.MODE_CBC, IV)
    padded = pad(base64_str.encode('utf-8'), AES.block_size)
    encrypted_bytes = cipher.encrypt(padded)

    # Step 3: Convert encrypted bytes to 0-f hex string
    hex_str = encrypted_bytes.hex()
    print(f"Step 2 - Encrypted  : {encrypted_bytes}")
    print(f"Step 3 - Hex (0-f)  : {hex_str}")

    return {
        "base64": base64_str,
        "encrypted_bytes": encrypted_bytes,
        "hex": hex_str
    }

def decrypt(hex_str: str) -> str:
    # Step 1: Convert hex string back to bytes
    encrypted_bytes = bytes.fromhex(hex_str)

    # Step 2: Decrypt using AES CBC
    cipher = AES.new(KEY, AES.MODE_CBC, IV)
    decrypted_padded = cipher.decrypt(encrypted_bytes)
    base64_str = unpad(decrypted_padded, AES.block_size).decode('utf-8')
    print(f"Step 4 - Base64     : {base64_str}")

    # Step 3: Decode Base64 back to original string
    original = base64.b64decode(base64_str).decode('utf-8')
    print(f"Step 5 - Original   : {original}")

    return original




# ── Example Usage ──────────────────────────────────────────
if __name__ == "__main__":
    message = """{
  "data": {
    "appVersion": 1,
    "brandInfo": {
      "[map_style]": [
        "satellite",
        "streets"
      ],
      "account_api_key": "your-own-information",
      "android_vibration_duration_ms": 250,
      "android_vibration_intensity": 70,
      "app_api_key": "your-own-information",
      "app_identifier": "gmap",
      "auth0_client_id": "your-own-information",
      "auth0_client_secret": "your-own-information",
      "auth0_domain": "https://arc-otp.us.auth0.com",
      "autocomplete_url": {
        "production": "https://ao9yvlrax5.execute-api.us-east-1.amazonaws.com/atl",
        "staging": "https://ao9yvlrax5.execute-api.us-east-1.amazonaws.com/atl"
      },
      "base_url": {
        "production": "https://zcl3o5i5ib.execute-api.us-east-1.amazonaws.com/prod",
        "staging": "https://zcl3o5i5ib.execute-api.us-east-1.amazonaws.com/prod"
      },
      "boundary": "32.066,-86.0856;35.7251,-81.9499",
      "enable_background_location_update": true,
      "enable_route_filter": false,
      "environment": "production",
      "graphql_base_url": {
        "production": "https://zcl3o5i5ib.execute-api.us-east-1.amazonaws.com/prod/otp/gtfs/v1",
        "staging": "https://zcl3o5i5ib.execute-api.us-east-1.amazonaws.com/prod/otp/gtfs/v1"
      },
      "ios_haptic_feedback_type": "sucess",
      "latitude_of_map_center": 33.956695,
      "live_tracking_deviation_waittime_seconds": 30,
      "logging_url": {
        "production": "https://logging.ibigroupmobile.com",
        "staging": "https://logging-test.ibigroupmobile.com"
      },
      "longitude_of_map_center": -83.98901,
      "map_style": "streets",
      "max_number_of_saved_trips": 5,
      "navigation_bar_height": 50,
      "realtime_businfo_refresh_interval": 30,
      "request_api_key": "your-own-information",
      "service_url": {
        "production": "https://st-push-middleware-test.ibi-transit.com/ext_api/otp_push",
        "staging": "https://st-push-middleware-test.ibi-transit.com/ext_api/otp_push"
      },
      "timezone": "America/Toronto",
      "zoom_level": 12
    },
    "feature": {
      "Indoor Navigation": {
        "detail": {
          "is_enabled": true,
          "jibestream_endpoint_url": "https://api.jibestream.com",
          "jibestream_client_id": "your-own-information",
          "jibestream_client_secret": "your-own-information",
          "jibesream_customer_id": 00,
          "extends_sdk_url": "https://v2.tendegrees.net",
          "extends_sdk_key_ios": "your-own-information",
          "extends_sdk_key_android": "your-own-information",
          "indoor_nav_deviation_distance_mm": 5000,
          "indoor_entrance_exit_popup_distance_mm": 3048,
          "indoor_nav_deviation_popup_count_max_number": 3,
          "indoor_nav_deviation_popup_wait_time_accumulate": false,
          "indoor_nav_deviation_popup_wait_time_seconds": 30,
          "indoor_entrance_exit_list_url": "https://ta-511.s3.us-east-1.amazonaws.com/otp/indoor_entrance_exit_list.json",
          "indoor_checking_active_route_entrance": true,
          "indoor_entrance_exit_checking_interval_secs": 5,
          "current_instruction_should_update_in_seconds": 2,
          "current_location_should_update_in_seconds": 1,
          "snap_to_wayfind_path_threshold_in_meter": 8,
          "currentLocation_upcoming_point_threshold_feet": 10,
          "indoor_ui_should_display_distance": false,
          "main_entrance_detection_radius_meters": 10,
          "indoor_main_entrance_list": "https://ta-511.s3.us-east-1.amazonaws.com/gmap/indoor_main_entrance_popup.json",
          "indoor_triggerable_locations": "https://ta-511.s3.amazonaws.com/gmap/jmap_triggerable_locations.json"
        },
        "note": "CXApp SDK integration for Indoor Navigation",
        "release": "2024-11-04"
      },
      "Live Tracking": {
        "release": "2025-06-10",
        "note": "Live Tracking for already saved trips",
        "detail": {
          "is_enabled": true,
          "live_tracking_deviation_waittime_seconds": 30,
          "live_tracking_repeat_instruction_waittime_seconds": 30
        }
      },
      "Login": {
        "release": "2023-08-16",
        "note": "Manage Login Page",
        "detail": {
          "is_enabled": true,
          "logo_height": 90,
          "logo_width": 90,
          "title": "",
          "enable_mobile_questionairs": true,
          "available_notification_methods": "Email,SMS,PushNotification,HapticFeedback",
          "url_terms_of_service": "https://ta-511.s3.amazonaws.com/otp/g-map_terms_of_use.html",
          "visible_store_trip_history_option": false,
          "url_terms_of_storage": "https://gmap.ibi-transit.com/#/terms-of-storage",
          "help_url": "https://georgia-map.com/"
        }
      },
      "Menu": {
        "release": "2023-08-16",
        "note": "Manage App Side Menu",
        "detail": {
          "is_enabled": true,
          "[action]": [
            "trigger external web",
            "trigger feedback",
            "trigger phone call",
            "none"
          ],
          "[order]": [
            0,
            1,
            2,
            3,
            4,
            5,
            6
          ],
          "items": {
            "Feedback": {
              "title": "Give Feedback",
              "icon": "ic_leavefeedbacks",
              "type": "trigger external web",
              "value": "https://arc-survey.vercel.app/",
              "isVisible": true,
              "order": 1
            },
            "FAQ": {
              "title": "FAQ",
              "icon": "ic_external_link",
              "type": "trigger external web",
              "value": "https://docs.google.com/document/d/1lax8Blu3vgrdKcHYrZyjhkSR24rcaefintQBj9d99bM/edit?tab=t.0#heading=h.excjk1gx0erl",
              "isVisible": true,
              "order": 2
            },
            "Help": {
              "title": "About Us",
              "icon": "ic_external_link",
              "type": "trigger external web",
              "value": "https://georgia-map.com/",
              "isVisible": true,
              "order": 3
            },
            "call": {
              "title": "Customer Service",
              "icon": "ic_callcenter",
              "type": "trigger phone call",
              "value": "7708225010",
              "isVisible": true,
              "order": 4
            }
          },
          "[type]": [
            "trigger external web",
            "trigger phone call",
            "none"
          ]
        }
      },
      "Modes": {
        "release": "2023-08-16",
        "note": "Used to manage the mode combination",
        "detail": {
          "is_enabled": true,
          "route_mode_overrides": "",
          "all_mode_list": "https://ta-511.s3.amazonaws.com/otp/gmap_mode_list.json",
          "route_mode_combinations_url": "https://atlrides.com/mode-combinations.json",
          "route_mode_agencies_mapping": "Gwinnett County Transit,Ride Gwinnett;Metropolitan Atlanta Rapid Transit Authority,MARTA;",
          "route_mode_name_mapping": "rail,MARTA Rail;tram,Atlanta Streetcar",
          "agencies_logo_base_url": "https://ta-511.s3.amazonaws.com/otp/agencies_logos/",
          "priorities_route_agency_order": true,
          "sorted_route_order_url": "https://ta-511.s3.us-east-1.amazonaws.com/otp/route_sorted_order.json"
        }
      },
      "Search": {
        "release": "2023-08-16",
        "note": "Provide the Configuration for the search mode candidates.",
        "detail": {
          "is_enabled": true,
          "enable_report_tracking_gps": true,
          "selectable_modes": "TRANSIT:BUS,SUBWAY,STREETCAR;BICYCLE;CAR",
          "search_error_list_mapping": "https://ta-511.s3.amazonaws.com/otp/error_mapping_list.json",
          "available_criterias": {
            "maximum_walk": "1/10,1/4,1/2,3/4,1,2,5",
            "walk_speed": "1:0.45,2:0.89,3:1.34,4:1.78,5:2.23",
            "optimize": "Speed,Fewest Transfers"
          },
          "[request_type]": [
            "RESTful API",
            "GraphQL API"
          ],
          "enable_start_route": true,
          "request_type": "GraphQL API",
          "default_criterias": {
            "maximum_walk": "3/4",
            "walk_speed": 3,
            "avoid_walking": false,
            "accessible_routing": false,
            "allow_bike_rental": true,
            "optimize": "Speed"
          }
        }
      },
      "Preview Trip":{
      "release":"2026-08-26",
      "note":"Preview trip for summarize saved trip",
      "detail":{
         "is_enabled":true
      }
   },
      "Travel Companion":{
      "release":"2026-08-26",
      "note":"Travel Companion for user can add travel companion for their trip as observers and companions",
      "detail":{
         "is_enabled":true
      }
   },
      "Mobility Profile":{
      "release":"2026-08-26",
      "note":"To preserve their mobility preference and obtain the trip plan accordingly.",
      "detail":{
         "is_enabled":true
      }
   },
      "Fare Information":{
      "release":"2026-08-26",
      "note":"To show fare information for each itinerary",
      "detail":{
         "is_enabled":false
      }
   },
      "Trip Details Card":{
      "release":"2026-08-26",
      "note":"To show trip details in summary card at the bottom of each trip",
      "detail":{
         "is_enabled":true
      }
   }
    },
    "revision": 0,
    "theme": {
      "Dark_Mode_Skin": "Dark",
      "Light_Mode_Skin": "Light",
      "Template": {
        "Dark": {
          "color": {
            "cameradetail_title_brandinfo_color": "#ffffff",
            "foreground_color": "#ffffff",
            "mask_background_color": "#cccccc",
            "menu_logo_color": "#eeeeee",
            "plan_trip_button_in_search_bg_color": "#008000",
            "plan_trip_button_in_search_font_color": "#FFFFFF",
            "primary_background_color": "#333533",
            "primary_color": "#606c38",
            "secondary_background_color": "#999999",
            "secondary_color": "#cccccc",
            "tertiary_color": "#ffffff",
            "toggle_off_color": "#999999",
            "toggle_on_color": "#606c38"
          },
          "font": {
            "body_font_size": 16,
            "footnote_font_size": 12,
            "primary_font_family": "Helvetica",
            "secondary_font_family": "Helvetica Neue",
            "title_font_size": 28
          }
        },
        "Light": {
          "color": {
            "cameradetail_title_brandinfo_color": "#ff0000",
            "foreground_color": "#000000",
            "mask_background_color": "#000000",
            "menu_logo_color": "#aaaaaa",
            "plan_trip_button_in_search_bg_color": "#008000",
            "plan_trip_button_in_search_font_color": "#FFFFFF",
            "primary_background_color": "#ffffff",
            "primary_color": "#b2d235",
            "secondary_background_color": "#979797",
            "secondary_color": "#056C78",
            "tertiary_color": "#3f4b50",
            "toggle_off_color": "#999999",
            "toggle_on_color": "#979797"
          },
          "font": {
            "body_font_size": 17,
            "footnote_font_size": 12,
            "primary_font_family": "Helvetica",
            "secondary_font_family": "Helvetica Neue",
            "title_font_size": 28
          }
        }
      }
    }
  }
}
    """
    # Encrypt
    result = encrypt(message)

    print("=" * 55)

    # Decrypt
    decrypted = decrypt(result["hex"])
    print("=" * 55)

    # Verify
    print(f"Match               : {message == decrypted}")
    print("==== Copy and Paste the encrypted content to your config.json file below: ====")
    print(result["hex"])
    print("==== Copy and Paste the encrypted content to your config.json file above: ====")


