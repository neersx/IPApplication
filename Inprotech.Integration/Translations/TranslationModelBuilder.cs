using System;
using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Translations
{
    public class TranslationModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException("modelBuilder");
            modelBuilder.Entity<TranslationDelta>();
        }
    }
}