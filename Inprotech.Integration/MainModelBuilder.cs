using System;
using System.Data.Entity;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration
{
    public class MainModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            modelBuilder.Entity<Case>();

            modelBuilder.Entity<Document>()
                .HasOptional(e => e.DocumentEvent)
                .WithRequired(e => e.Document);

            modelBuilder.Entity<CaseFiles.CaseFiles>();

            modelBuilder.Entity<ConfigSetting>();
        }
    }
}