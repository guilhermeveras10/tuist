import ProjectDescription
import ProjectDescriptionHelpers
import MyPlugin

let localHelper = LocalHelper(name: "MyPlugin")

let project = Project(
    name: "PersonalProject",
    organizationName: AppSetup.appConfig.organizationName,
    targets: AppTarget.allCases.map(\.target),
    resourceSynthesizers: [
        .strings(),
        .assets(),
    ]
)
