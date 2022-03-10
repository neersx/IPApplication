using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Integration.DmsIntegration.Data;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using Document = Inprotech.Integration.Documents.Document;

namespace Inprotech.Integration.DmsIntegration
{
    class MetadataBuilder : IBuildXmlMetadata
    {
        const string DocItem = "DMS_INTEGRATION_DOCUMENT_METADATA";
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRuner;

        public MetadataBuilder(IDbContext dbContext, IDocItemRunner docItemRuner)
        {
            _dbContext = dbContext;
            _docItemRuner = docItemRuner;
        }

        public Stream Build(int caseId, Document document)
        {
            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Single(_ => _.Id == caseId);
            var docitem = _dbContext.Set<DocItem>().Single(_ => _.Name == DocItem);
            var metadata = new DocumentMetadataType();
            var dataset = _docItemRuner.Run(docitem.Id, new Dictionary<string, object> {{"gstrEntryPoint", @case.Irn}});
            var datarow = dataset.Tables[0].Rows[0];

            metadata.DataSource = ConvertDataSourceType(document.Source);
            metadata.MatterRef = datarow.Field<string>("MatterRef");
            metadata.ResponsibleAttorney = new NameType { code = datarow.Field<string>("ResponsibleAttorneyCode"), Value = datarow.Field<string>("ResponsibleAttorneyName") };
            metadata.Paralegal = new NameType { code = datarow.Field<string>("ParalegalCode"), Value = datarow.Field<string>("ParalegalName") };
            metadata.Client = new NameType { code = datarow.Field<string>("ClientCode"), Value = datarow.Field<string>("ClientName") };
            metadata.ResponsibleOffice = datarow.Field<string>("ResponsibleOffice");
            metadata.DocumentDate = document.MailRoomDate;
            metadata.Description = document.DocumentDescription;

            var serializer = new System.Xml.Serialization.XmlSerializer(metadata.GetType());
            var stream = new MemoryStream();
            serializer.Serialize(stream, metadata);
            stream.Seek(0, SeekOrigin.Begin);

            return stream;
        }

        static Data.DataSourceType ConvertDataSourceType(DataSourceType type)
        {
            return (Data.DataSourceType) Enum.Parse(typeof (Data.DataSourceType), type.ToString());
        }
    }
}