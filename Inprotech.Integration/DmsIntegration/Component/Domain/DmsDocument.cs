using System;
using System.Collections.Generic;

namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DmsDocument
    {
        public DmsDocument()
        {
            RelatedDocuments = new List<DmsDocument>();
        }

        public string ContainerId { get; set; }

        public int Id { get; set; }

        public string SiteDbId { get; set; }

        public string Database { get; set; }

        public string Description { get; set; }

        public int Version { get; set; }

        public int Size { get; set; }

        public DateTime? DateCreated { get; set; }

        public DateTime? DateEdited { get; set; }

        public string DocTypeName { get; set; }

        public string DocTypeDescription { get; set; }

        public string AuthorInitials { get; set; }

        public string AuthorFullName { get; set; }

        public string ApplicationExtension { get; set; }

        public string ApplicationName { get; set; }

        public string ApplicationDescription { get; set; }

        public string Comment { get; set; }

        public bool HasAttachments { get; set; }

        public string EmailFrom { get; set; }

        public string EmailTo { get; set; }

        public string EmailCc { get; set; }

        public DateTime? EmailDateSent { get; set; }

        public DateTime? EmailDateReceived { get; set; }

        public Uri Iwl { get; set; }

        public List<DmsDocument> RelatedDocuments { get; set; }

        public bool HasRelatedDocuments { get; set; }

        public bool ProfileLoaded { get; set; }

        public string SubClass { get; set; }

        public void AddRelatedDocument(int id, string database, int? version)
        {
            RelatedDocuments.Add(new DmsDocument {Id = id, Database = database, Version = version ?? 1});
        }
    }
}