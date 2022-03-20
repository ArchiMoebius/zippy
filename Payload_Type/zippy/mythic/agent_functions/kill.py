from mythic_payloadtype_container.MythicCommandBase import *
from mythic_payloadtype_container.MythicRPC import *


class KillArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="pid",
                type=ParameterType.Number,
                description="ID of Process to Terminate",
            )
        ]

    async def parse_arguments(self):

        if len(self.command_line) > 0:
            self.add_arg("pid", self.command_line)

    async def parse_dictionary(self, dictionary_arguments):
        self.load_args_from_dictionary(dictionary_arguments)


class KillCommand(CommandBase):
    cmd = "kill"
    needs_admin = False
    help_cmd = "kill pid"
    description = "Terminate process by ID"
    version = 1
    author = "@ajpc500"
    attackmapping = []
    supported_ui_features = ["process_browser:kill"]
    argument_class = KillArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = (
            f'Terminating process with PID: {str(task.args.get_arg("pid"))}'
        )

        return task

    async def process_response(self, response: AgentResponse):
        pass
