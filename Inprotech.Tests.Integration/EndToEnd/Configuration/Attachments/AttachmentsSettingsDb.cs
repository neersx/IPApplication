using System.Data.Entity.Migrations;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments
{
    public class AttachmentsSettingsDb : DbSetup
    {
        public void Setup(AttachmentSetting settings)
        {
            Do(x =>
            {
                x.DbContext.Set<ExternalSettings>()
                 .AddOrUpdate(new ExternalSettings(KnownExternalSettings.Attachment)
                 {
                     IsComplete = true,
                     Settings = CryptoService.Encrypt(JsonConvert.SerializeObject(settings))
                 });
                x.DbContext.SaveChanges();
            });
        }
    }
}