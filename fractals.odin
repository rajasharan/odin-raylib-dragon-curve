// https://www.youtube.com/watch?v=hjhMh0R9T1Y
// https://itch.io/jam/odin-7-day-jam
// https://github.com/karl-zylinski/odin-raylib-web

package example

import fmt "core:fmt"
import math "core:math"
import rl "vendor:raylib"

main :: proc() {
    W :: 1280
    H :: 720
    rl.SetConfigFlags({ .VSYNC_HINT })
    rl.InitWindow(W, H, "Fractals: Dragon Curve")

    camera := rl.Camera2D {
        offset = {W/2, H/2},
        zoom = 1,
    }

    start_point := rl.Vector2{0,0}
    end_point := rl.Vector2{10, 0}
    points :[dynamic]rl.Vector2
    append(&points, start_point, end_point)

    for _ in 0..<10 {
        l := points[len(points)-1]
        for i:=len(points)-2; i>=0; i-=1 {
            p := points[i]
            n := rl.Vector2{l.x + l.y - p.y, l.y - l.x + p.x} // 90° clockwise rotation of p around l
            append(&points, n)
        }
    }

    a := start_point
    b := end_point
    current_index := 1
    remaining :f32 = 0

    pos := rl.Vector2{}
    is_panning := false
    prev_mouse_pos :rl.Vector2
    current_mouse_pos :rl.Vector2

    draw_menu := false
    close_game := false
    for !rl.WindowShouldClose() && !close_game {
        // updates
        dt := rl.GetFrameTime()

        if rl.IsMouseButtonDown(.LEFT) {
            if !is_panning {
                is_panning = true
                prev_mouse_pos = rl.GetMousePosition()
            } else {
                current_mouse_pos = rl.GetMousePosition()
                mouse_delta :=  prev_mouse_pos - current_mouse_pos
                camera.offset -= mouse_delta
                prev_mouse_pos = current_mouse_pos
            }
        }
        else if rl.IsMouseButtonUp(.LEFT) && is_panning {
            is_panning = false
        }

        // drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)
        rl.BeginMode2D(camera)
        {
            for i in 0..<current_index-1 { // draw all the past lines immediately
                if i+1 < len(points) {
                    rl.DrawLineV(points[i], points[i+1], rl.RAYWHITE)
                }
            }
            if !draw_menu {
                if remaining < 1 { // draw the current line (ab) incrementally using Lerp
                    b_prime := rl.Vector2{rl.Lerp(a.x, b.x, remaining), rl.Lerp(a.y, b.y, remaining)}
                    rl.DrawLineV(a, b_prime, rl.RAYWHITE)
                    remaining += 50 * dt
                }
                else { // move to next point
                    current_index += 1
                    if current_index < len(points) {
                        a = b
                        b = points[current_index]
                        remaining = 0
                    } else {
                        draw_menu = true
                    }
                }
            }
        }
        rl.EndMode2D()
        if draw_menu {
            result := rl.GuiMessageBox({W/2 - W/16, 10, W/8, H/8}, "Simulation Complete", rl.TextFormat("Want to keep going?\nNext: %d points", 2*current_index -1), "OK\nCancel")
            if result == 0 || result == 2 {
                fmt.println("menu: ", result)
                close_game = true
            } else if result == 1 {
                draw_menu = false
                l := points[len(points)-1]
                for i:=len(points)-2; i>=0; i-=1 {
                    p := points[i]
                    n := rl.Vector2{l.x + l.y - p.y, l.y - l.x + p.x}
                    append(&points, n)
                }
            }
        }
        rl.DrawText("Drag with mouse\nto pan around", 10, 10, 15, rl.GRAY)
        rl.DrawFPS(W-150, 10)
        rl.DrawText(rl.TextFormat("points: %d", current_index), W-150, 30, 15, rl.RAYWHITE)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}
