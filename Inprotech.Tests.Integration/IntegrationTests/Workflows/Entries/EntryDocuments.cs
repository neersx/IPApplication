using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EntryDocuments : IntegrationTest
    {
        [Test]
        public void ShouldPropagateChangesToDescendants()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
            {
                var document1 = x.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document1"),
                    DocumentType = 1
                });
                var document2 = x.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document2"),
                    DocumentType = 1
                });
                var document3 = x.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document3"),
                    DocumentType = 1
                });
                var document4 = x.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document4"),
                    DocumentType = 1
                });

                return new
                {
                    document1,
                    document2,
                    document3,
                    document4
                };
            });

            var entryToUpdate = data.Parent.FirstEntry();

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = entryToUpdate.Id,
                              Description = entryToUpdate.Description,
                              ApplyToDescendants = true,
                              DocumentsDelta = new Delta<EntryDocumentDelta>
                              {
                                  Added = new[]
                                  {
                                      new EntryDocumentDelta(arg.document1.Id, true),
                                      new EntryDocumentDelta(arg.document2.Id, false),
                                      new EntryDocumentDelta(arg.document3.Id, true)
                                  }
                              }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var grandChild22 = result[data.GrandChild22.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];
                var ggcDocumentRequirements = greatGrandChild211.DocumentRequirements.OrderBy(_ => _.Document.Name);
                const int docCount = 3;

                Assert.AreEqual(docCount, parent.DocumentRequirements.Count, $"Should add the {docCount} documents to parent.");
                Assert.AreEqual(docCount, child1.DocumentRequirements.Count, $"Should add the {docCount} documents to child.");
                Assert.AreEqual(docCount, child2.DocumentRequirements.Count, $"Should add the {docCount} documents to child.");
                Assert.AreEqual(docCount, grandChild21.DocumentRequirements.Count, $"Should add the {docCount} documents to grandchild.");
                Assert.AreEqual(docCount, grandChild22.DocumentRequirements.Count, $"Should add the {docCount} documents to grandchild.");
                Assert.AreEqual(docCount, greatGrandChild211.DocumentRequirements.Count, $"Should add the {docCount} documents to greatgrandchild.");

                Assert.AreEqual(arg.document1.Id, ggcDocumentRequirements.ElementAt(0).DocumentId, "Should have correct documentIds in greatgrandchild.");
                Assert.IsTrue(ggcDocumentRequirements.ElementAt(0).IsMandatory, "doc1 is mandatory.");
                Assert.IsFalse(ggcDocumentRequirements.ElementAt(1).IsMandatory, "doc2 is not mandatory mandatory.");
                Assert.AreEqual(3, greatGrandChild211.DocumentRequirements.Count(_ => _.IsInherited), "The inheritance flag must be set for 3 documents in greatgrandchild.");
            }

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = entryToUpdate.Id,
                              Description = entryToUpdate.Description,
                              ApplyToDescendants = true,
                              DocumentsDelta = new Delta<EntryDocumentDelta>
                              {
                                  Updated = new[]
                                  {
                                      new EntryDocumentDelta(arg.document2.Id, true)
                                      {
                                          PreviousDocumentId = arg.document2.Id
                                      },
                                      new EntryDocumentDelta(arg.document4.Id, true)
                                      {
                                          PreviousDocumentId = arg.document1.Id
                                      }
                                  },
                                  Deleted = new[]
                                  {
                                      new EntryDocumentDelta(arg.document3.Id, true)
                                  }
                              }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var grandChild22 = result[data.GrandChild22.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];
                var ggcDocumentRequirements = greatGrandChild211.DocumentRequirements.OrderBy(_ => _.Document.Name);
                const int docCount = 2;

                Assert.AreEqual(docCount, parent.DocumentRequirements.Count, $"Should add the {docCount} documents to parent.");
                Assert.AreEqual(docCount, child1.DocumentRequirements.Count, $"Should add the {docCount} documents to child.");
                Assert.AreEqual(docCount, child2.DocumentRequirements.Count, $"Should add the {docCount} documents to child.");
                Assert.AreEqual(docCount, grandChild21.DocumentRequirements.Count, $"Should add the {docCount} documents to grandchild.");
                Assert.AreEqual(docCount, grandChild22.DocumentRequirements.Count, $"Should add the {docCount} documents to grandchild.");
                Assert.AreEqual(docCount, greatGrandChild211.DocumentRequirements.Count, $"Should add the {docCount} documents to greatgrandchild.");

                Assert.AreEqual(arg.document2.Id, ggcDocumentRequirements.First().DocumentId, "Should have correct documentIds in greatgrandchild.");
                Assert.IsTrue(ggcDocumentRequirements.First().IsMandatory, "doc1 is mandatory.");

                Assert.IsNull(ggcDocumentRequirements.FirstOrDefault(_ => _.DocumentId == arg.document1.Id), "This document was updated to document4");
                Assert.IsNull(ggcDocumentRequirements.FirstOrDefault(_ => _.DocumentId == arg.document3.Id), "This document was deleted");

                Assert.AreEqual(2, greatGrandChild211.DocumentRequirements.Count(_ => _.IsInherited), "The inheritance flag must be set for 2 documents in greatgrandchild.");
            }
        }
    }
}