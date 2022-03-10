using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Translations
{
    public class TranslationsModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder builder)
        {
            builder.Entity<TranslatedText>();

            builder.Entity<TranslationSource>();
            builder.Entity<TranslatedItem>();
        }
    }
}