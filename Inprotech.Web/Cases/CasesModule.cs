using Autofac;
using Inprotech.Web.Attachment;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.Details.DesignatedJurisdiction;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Components.Cases.Screens;

namespace Inprotech.Web.Cases
{
    public class CasesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseHeaderFieldMapper>().As<ICaseViewFieldMapper>();
            builder.RegisterType<ActionEvents>().As<IActionEvents>();
            builder.RegisterType<CaseViewEvents>().As<ICaseViewEvents>();
            builder.RegisterType<CaseViewOfficialNumbers>().As<ICaseViewOfficialNumbers>();
            builder.RegisterType<RelatedCases>().As<IRelatedCases>();
            builder.RegisterType<CaseViewEventsDueDateClientFilter>().As<ICaseViewEventsDueDateClientFilter>();
            builder.RegisterType<CaseTextSection>().As<ICaseTextSection>();
            builder.RegisterType<DesignatedJurisdictions>().As<IDesignatedJurisdictions>();
            builder.RegisterType<ClientNameDetails>().As<IClientNameDetails>();
            builder.RegisterType<CaseViewNamesProvider>().As<ICaseViewNamesProvider>();
            builder.RegisterType<CaseView>().As<ICaseView>();
            builder.RegisterType<CaseHeaderDescription>().As<ICaseHeaderDescription>();
            builder.RegisterType<DefaultCaseImage>().As<IDefaultCaseImage>();
            builder.RegisterType<CaseEmailTemplate>().As<ICaseEmailTemplate>();
            builder.RegisterType<CaseEmailTemplateParametersResolver>().As<ICaseEmailTemplateParametersResolver>();
            builder.RegisterType<CaseViewEfiling>().As<ICaseViewEfiling>();
            builder.RegisterType<EfilingFileViewer>().As<IEfilingFileViewer>();
            builder.RegisterType<ClassesTextResolver>().As<IClassesTextResolver>();
            builder.RegisterType<CaseClasses>().As<ICaseClasses>();
            builder.RegisterType<EFilingCompatibility>().As<IEFilingCompatibility>()
                   .OnActivating(_ => _.Instance.Check())
                   .SingleInstance();
            builder.RegisterType<CaseRenewalDetails>().As<ICaseRenewalDetails>();
            builder.RegisterType<CaseStandingInstructions>().As<ICaseStandingInstructions>();
            builder.RegisterType<CaseViewStandingInstructions>().As<ICaseViewStandingInstructions>();
            builder.RegisterType<CaseChecklistDetails>().As<ICaseChecklistDetails>();
            builder.RegisterType<CaseViewAttachmentsProvider>().As<ICaseViewAttachmentsProvider>();
            builder.RegisterType<CaseActivityAttachmentMaintenance>().As<IActivityAttachmentMaintenance>().Keyed<IActivityAttachmentMaintenance>(AttachmentFor.Case).WithParameter("attachmentFor", AttachmentFor.Case);
        }
    }
}