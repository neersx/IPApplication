using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.InproDoc;
using Inprotech.Web.InproDoc.Dto;
using InprotechKaizen.Model.Components.DocumentGeneration;
using Newtonsoft.Json;
using NUnit.Framework;
using DocItem = Inprotech.Web.InproDoc.Dto.DocItem;

namespace Inprotech.Tests.Integration.IntegrationTests.InproDoc
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class InproDocControllerTest : IntegrationTest
    {
        class MaxElapsedSecondsAllowed
        {
            public const int EvalOnRegister = 10;
            public const int Batched = 5;
        }

        [Test]
        public void InproDocExecutionScenario()
        {
            var tryConnectResult = ApiClient.Post<string>("inproDoc/ping", null);
            Assert.AreEqual("pong", JsonConvert.DeserializeObject<string>(tryConnectResult), "try connect function should work");

            var entryPointsResult = ApiClient.Post<IEnumerable<EntryPoint>>("inproDoc/entry-points", null).ToList();
            Assert.AreEqual(5, entryPointsResult.Count, "there must be 4 entry points");
            Assert.AreEqual(1, entryPointsResult.Count(x => x.Description.Equals("The Refererence (IRN) of a Case")), "case reference should be an entry point");
            Assert.AreEqual(1, entryPointsResult.Count(x => x.Description.Equals("The Code of a Name")), "name code should be an entry point");
            Assert.AreEqual(1, entryPointsResult.Count(x => x.Description.Equals("The Question No")), "question number should be an entry point");
            Assert.AreEqual(1, entryPointsResult.Count(x => x.Description.Equals("The NameNo of a Name")), "name of a name should be an entry point");
            Assert.AreEqual(1, entryPointsResult.Count(x => x.Description.Equals("The Activity Request ID")), "activity request identifier should be an entry point");

            var documentsResult = ApiClient.Post<DocumentList>("inproDoc/documents-by-type",
                                                               JsonConvert.SerializeObject(new DocumentListRequest
                                                               {
                                                                   DocumentType = DocumentType.Word,
                                                                   NotUsedBy = LetterConsumers.DgLib,
                                                                   UsedBy = LetterConsumers.Cases | LetterConsumers.Names
                                                               }));
            Assert.IsTrue(documentsResult != null &&
                          documentsResult.Documents != null &&
                          documentsResult.Documents.Any(), "some documents must be returned when listing documents");

            var docItemsResult = ApiClient.Post<IEnumerable<ItemProcessorResponse>>("inproDoc/run-doc-items",
                                                                                    JsonConvert.SerializeObject(new[]
                                                                                    {
                                                                                        new ItemProcessorRequest
                                                                                        {
                                                                                            EntryPointValue = "1234/a",
                                                                                            DocItem = new DocItem
                                                                                            {
                                                                                                ItemName = "ENTRY_POINT_1"
                                                                                            }
                                                                                        }
                                                                                    })).ToList();

            Assert.IsTrue(docItemsResult != null &&
                          docItemsResult.Count == 1 &&
                          docItemsResult[0].TableResultSets.Count == 1 &&
                          docItemsResult[0].TableResultSets[0].RowResultSets.Count == 1, "document item must be executed and return result");
        }

        [Test]
        public void InproDocEvalOnRegisterExecutionShouldBeQuick()
        {
            var items = JsonConvert.DeserializeObject<IEnumerable<ItemProcessorRequest>>(From.EmbeddedAssets("inprodoc-run-doc-item.json"));

            var stopwatch = new Stopwatch();
            stopwatch.Start();

            foreach (var item in items)
            {
                var r = ApiClient.Post<IEnumerable<ItemProcessorResponse>>("inproDoc/run-doc-items",
                                                                           JsonConvert.SerializeObject(new[] {item})).ToArray();

                Assert.IsNotEmpty(r, "document item must be executed and return result");
                Assert.IsTrue(r.All(_ => string.IsNullOrEmpty(_.Exception)), "should not raise exceptions");
            }

            stopwatch.Stop();

            Assert.LessOrEqual(stopwatch.Elapsed.TotalSeconds, MaxElapsedSecondsAllowed.EvalOnRegister,
                               $"Should complete all doc items evaluation within {MaxElapsedSecondsAllowed.EvalOnRegister} seconds, but is {stopwatch.Elapsed.TotalSeconds} instead");
        }

        [Test]
        public void InproDocDefaultExecutionShouldBeQuicker()
        {
            var items = JsonConvert.DeserializeObject<IEnumerable<ItemProcessorRequest>>(From.EmbeddedAssets("inprodoc-run-doc-item.json")).ToArray();

            var stopwatch = new Stopwatch();
            stopwatch.Start();

            var r = ApiClient.Post<IEnumerable<ItemProcessorResponse>>("inproDoc/run-doc-items",
                                                                       JsonConvert.SerializeObject(items)).ToArray();

            stopwatch.Stop();

            Assert.AreEqual(items.Length, r.Length, "should return the same number of items as was requested");
            Assert.IsTrue(r.All(_ => string.IsNullOrEmpty(_.Exception)), "should not raise exceptions");
            Assert.LessOrEqual(stopwatch.Elapsed.TotalSeconds, MaxElapsedSecondsAllowed.Batched,
                               $"Should complete all doc items evaluation within {MaxElapsedSecondsAllowed.Batched} seconds, but is {stopwatch.Elapsed.TotalSeconds} instead");
        }
    }
}