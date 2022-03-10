using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{
    public class BillReviewModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillReviewSettingsResolver>().As<IBillReviewSettingsResolver>();
            builder.RegisterType<EmailRecipientsProvider>().As<IEmailRecipientsProvider>();
            builder.RegisterType<EmailSubjectBodyResolver>().As<IEmailSubjectBodyResolver>();
            builder.RegisterType<BillReviewEmailBuilder>().As<IBillReviewEmailBuilder>();
            builder.RegisterType<BillReview>().As<IBillReview>();
        }
    }
}