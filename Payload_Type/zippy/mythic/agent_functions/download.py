import json
import shlex

from mythic_payloadtype_container.MythicCommandBase import *
from mythic_payloadtype_container.MythicRPC import *


class DownloadArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        if len(self.command_line.strip()) == 0:
            raise Exception(
                "Require a path to download.\n\tUsage: {}".format(
                    DownloadCommand.help_cmd
                )
            )

        filename = ""

        if self.command_line[0] == "{":
            temp_json = json.loads(self.command_line)
            filename = temp_json["path"] + "/" + temp_json["file"]
        else:

            args = shlex.split(self.command_line)

            self.add_arg(
                "file_path", args[0], ParameterType.String
            )  # TODO: support multiple files at once? pass files, args?...

        if filename != "":
            self.add_arg("file_path", filename, ParameterType.String)


class DownloadCommand(CommandBase):
    cmd = "download"
    needs_admin = False
    help_cmd = "download {filepath} ... {filepath}"
    description = (
        "Download one or more a files from the victim machine - parsed as POSIX paths"
    )
    version = 1
    supported_ui_features = ["file_browser:download"]
    is_download_file = True
    author = "@ajpc500"
    parameters = []
    attackmapping = ["T1020", "T1030", "T1041"]
    argument_class = DownloadArguments
    browser_script = []
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        return task

    async def process_response(self, response: AgentResponse):
        pass
