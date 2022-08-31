open Spatial_ipc

let default_icon = ""
let empty_workspace_icon = "◯"

let icon_of = function
  | "firefox" -> Some ""
  | "kitty" -> Some ""
  | "Slack" -> Some ""
  | "emacs" -> Some ""
  | _ -> None

let workspace_icon workspace windows =
  List.assq_opt workspace windows |> function
  | Some app_id -> Option.value ~default:default_icon (icon_of app_id)
  | None -> empty_workspace_icon

let () =
  Clap.description "A client to communicate with a Spatial instance.";

  let ty = Clap.default_string ~short:'t' ~last:true "run_command" in

  match ty with
  | "run_command" ->
      let cmd = Clap.mandatory_string ~placeholder:"CMD" () in
      Clap.close ();

      let cmd = command_of_string_exn cmd in
      let { success } = send_command (Run_command cmd) in
      if not success then exit 1
  | "get_windows" -> (
      let cmd = Clap.optional_int ~placeholder:"INDEX" () in
      Clap.close ();

      let reply = send_command Get_windows in

      match (cmd, reply.focus) with
      | Some idx, Some focus when idx < List.length reply.windows ->
          let tooltip = List.nth reply.windows idx in
          let name =
            Option.value
              ~default:(default_icon ^ " " ^ tooltip)
              (icon_of tooltip)
          in
          let cls = if idx = focus then "focus" else "unfocus" in
          Format.(printf "%s\n%s\n%s" name tooltip cls)
      | Some _, _ -> ()
      | None, _ ->
          List.iteri
            (fun idx name ->
              let marker = if reply.focus = Some idx then "*" else "" in
              Format.printf "| %s%s%s | " marker name marker)
            reply.windows)
  | "get_workspaces" -> (
      let cmd = Clap.optional_int ~placeholder:"INDEX" () in
      Clap.close ();

      let reply = send_command Get_workspaces in

      match cmd with
      | Some i ->
          let cls = if i = reply.current then "focus" else "unfocused" in
          Format.(
            printf "%s\n%s\n%s"
              (workspace_icon i reply.windows)
              (string_of_int i) cls)
      | None ->
          Format.(
            printf "%a@?"
              (pp_print_list
                 ~pp_sep:(fun fmt () -> pp_print_string fmt "  ")
                 (fun fmt k ->
                   Format.printf "%d:%s" k (workspace_icon k reply.windows)))
              (List.init 6 (fun x -> x + 1))))
  | _ -> exit 2
