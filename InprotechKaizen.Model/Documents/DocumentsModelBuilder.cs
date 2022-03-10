using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Documents
{
    public class DocumentsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException(nameof(modelBuilder));

            modelBuilder.Entity<Document>();
            modelBuilder.Entity<DocumentSubstitute>();
            modelBuilder.Entity<DeliveryMethod>();
            
            modelBuilder.Entity<DocItem>();
            modelBuilder.Entity<Group>();
            modelBuilder.Entity<ItemGroup>();
            modelBuilder.Entity<ItemNote>();
            modelBuilder.Entity<FormFields>();

            modelBuilder.Entity<ReportParameter>();
        }
    }
}