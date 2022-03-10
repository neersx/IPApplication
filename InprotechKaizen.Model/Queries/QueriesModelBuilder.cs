using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Queries
{
    public class QueriesModelBuilder : IModelBuilder
    {
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Query>();
            modelBuilder.Entity<QueryContextModel>();
            modelBuilder.Entity<QueryFilter>();
            modelBuilder.Entity<QueryColumn>();
            modelBuilder.Entity<QueryContent>();
            modelBuilder.Entity<QueryDataItem>();
            modelBuilder.Entity<QueryGroup>();
            modelBuilder.Entity<QueryPresentation>();
            modelBuilder.Entity<QueryContextColumn>();
            modelBuilder.Entity<QueryColumnGroup>();
            modelBuilder.Entity<QueryImpliedData>();
            modelBuilder.Entity<QueryImpliedItem>();
            modelBuilder.Entity<TopicDataItems>();
        }
    }
}