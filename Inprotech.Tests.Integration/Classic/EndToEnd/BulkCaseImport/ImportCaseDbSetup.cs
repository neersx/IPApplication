using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class ImportCaseDbSetup : DbSetup
    {
        static readonly string StorageLocation = Path.Combine(Env.StorageLocation, "bulkcaseimport");

        public static dynamic LastImported()
        {
            return Do(x =>
                      {
                          var last = x.DbContext.Set<EdeSenderDetails>()
                                      .OrderByDescending(o => o.RowId)
                                      .First();

                          return new
                                 {
                                     last.TransactionHeader.BatchId,
                                     last.SenderFileName,
                                     last.Sender,
                                     last.SenderRequestType,
                                     last.SenderRequestIdentifier,
                                     CpaXml = LastImportedCpaXml(),
                                     RelatedCasesCount = RelatedCasesCount(GetLastImportedFileName())
                                 };
                      });
        }

        static string GetLastImportedFileName()
        {
            var directory = new DirectoryInfo(StorageLocation);

            var lastSubFolder = directory.GetDirectories().OrderByDescending(_ => _.LastWriteTime).FirstOrDefault();

            return lastSubFolder?.GetFiles().FirstOrDefault()?.FullName;
        }

        static string LastImportedCpaXml()
        {
            var cpaxml = GetLastImportedFileName();

            return string.IsNullOrEmpty(cpaxml) ? null : File.ReadAllText(cpaxml);
        }

        static List<dynamic> RelatedCasesCount(string content)
        {
            var doc = XDocument.Load(content);

            var transactions = doc.Root.Descendants("TransactionBody");
            var transactiondetails = new List<dynamic>();
            foreach (var t in transactions)
            {
                var relatedCases = t.Descendants("AssociatedCaseDetails").Count();
                transactiondetails.Add(new
                                       {
                                           TransactionId = t.Descendants("TransactionIdentifier").Single().Value,
                                           RelatedCasesCount = relatedCases
                                       });
            }
            return transactiondetails;
        }

        public NameAlias CreateNameWithEdeIdentifier(string nameCode)
        {
            var name = new Name{NameCode = nameCode, LastName = RandomString.Next(8)};
            InsertWithNewId(name);
            var aliasType = DbContext.Set<NameAliasType>().Single(_ => _.Code == KnownAliasTypes.EdeIdentifier);

            var nameAlias = new NameAlias{Name = name, AliasType = aliasType, Country = null, PropertyType = null, Alias = RandomString.Next(8)};
            InsertWithNewId(nameAlias);

            return nameAlias;
        }
    }
}