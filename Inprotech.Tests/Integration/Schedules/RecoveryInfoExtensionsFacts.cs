using System.Linq;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class RecoveryInfoExtensionsFacts
    {
        public class LoadMethod
        {
            [Fact]
            public void LoadsMultipleRecoveryInfo()
            {
                var info = new[]
                {
                    new RecoveryInfo
                    {
                        CorrelationId = "1234"
                    },
                    new RecoveryInfo
                    {
                        CorrelationId = "4567"
                    }
                };

                var infoSerialised = JsonConvert.SerializeObject(info);

                var result = infoSerialised.Load().ToArray();

                Assert.Equal("1234", result.First().CorrelationId);
                Assert.Equal("4567", result.Last().CorrelationId);
            }

            [Fact]
            public void LoadsSingleRecoveryInfo()
            {
                var serialised = JsonConvert.SerializeObject(new RecoveryInfo());

                var result = serialised.Load().ToArray();

                Assert.NotNull(result.Single());
            }
        }
    }

    public class IsEmptyMethod
    {
        [Fact]
        public void ReturnsEmptyWhenNothingIsAvailable()
        {
            Assert.True(
                        new[]
                        {
                            new RecoveryInfo(),
                            new RecoveryInfo()
                        }.IsEmpty());
        }

        [Fact]
        public void ReturnsNotEmptyWhenSomethingIsAvailable()
        {
            Assert.False(
                         new[]
                         {
                             new RecoveryInfo
                             {
                                 CaseIds = new[] {1}
                             },
                             new RecoveryInfo()
                         }.IsEmpty());
        }
    }

    public class CorrelationOfMethod
    {
        [Fact]
        public void ReturnsAllCorrelatedIdThatTheCaseBelongsTo()
        {
            const int firstCase = 1;
            const int secondCase = 2;

            var recoveryInfos =
                new[]
                {
                    new RecoveryInfo
                    {
                        CorrelationId = "1245",
                        CaseIds = new[] {firstCase, secondCase}
                    },
                    new RecoveryInfo
                    {
                        CorrelationId = "4567",
                        CaseIds = new[] {secondCase}
                    }
                };

            Assert.Equal(new[] {"1245", "4567"}, recoveryInfos.CorrelationshipOf(secondCase, null));
            Assert.Equal(new[] {"1245"}, recoveryInfos.CorrelationshipOf(firstCase, null));
        }

        [Fact]
        public void ReturnsAllCorrelatedIdThatTheDocumentBelongsTo()
        {
            const int firstDocument = 1;
            const int secondDocument = 2;

            var recoveryInfos =
                new[]
                {
                    new RecoveryInfo
                    {
                        CorrelationId = "1245",
                        DocumentIds = new[] {firstDocument, secondDocument}
                    },
                    new RecoveryInfo
                    {
                        CorrelationId = "4567",
                        DocumentIds = new[] {secondDocument}
                    }
                };

            Assert.Equal(new[] {"1245", "4567"}, recoveryInfos.CorrelationshipOf(null, secondDocument));
            Assert.Equal(new[] {"1245"}, recoveryInfos.CorrelationshipOf(null, firstDocument));
        }
    }
}