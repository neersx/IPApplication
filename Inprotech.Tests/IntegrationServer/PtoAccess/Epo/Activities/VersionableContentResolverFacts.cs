using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Serialization;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Epo.Activities;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Activities
{
    public class VersionableContentResolverFacts
    {
        const string AssetPath = "Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Assets.";

        static string Modify(string content, Action<registerdocument> modifyBeforeReturning)
        {
            var serializer = new XmlSerializer(typeof(worldpatentdata));

            var data = (worldpatentdata) serializer.Deserialize(new StringReader(content));

            var registerdocument = data.registersearch.registerdocuments.Single().registerdocument.Single();

            modifyBeforeReturning(registerdocument);

            using (var sw = new StringWriter())
            {
                serializer.Serialize(sw, data);
                return sw.ToString();
            }
        }

        public class VersionableContentResolverFixture : IFixture<VersionableContentResolver>
        {
            public VersionableContentResolverFixture()
            {
                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                DataDownloadLocationResolver.Resolve(Arg.Any<DataDownload>())
                                            .Returns("hello world");

                Subject = new VersionableContentResolver(DataDownloadLocationResolver, BufferedStringReader);
            }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public VersionableContentResolver Subject { get; set; }

            public VersionableContentResolverFixture WithRawContent(string xml)
            {
                BufferedStringReader.Read(Arg.Any<string>())
                                    .Returns(Task.FromResult(xml));

                return this;
            }
        }

        [Fact]
        public async Task DoesNotIgnoreNameChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x =>
            {
                var nameNode = x.bibliographicdata.parties.applicants[0].applicant[0].addressbook[0].Items.Where(i => i is name).OfType<name>().FirstOrDefault();
                if (nameNode != null)
                {
                    nameNode.Text = new[] {"New Name"};
                }
            });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task DoesNotIgnoreOfficialNumberChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x => { x.bibliographicdata.applicationreference[0].changegazettenum = Fixture.Today().ToString("yyyyMMdd") + "/1"; });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task DoesNotIgnorePriorityClaimChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x => { x.bibliographicdata.priorityclaims[0].priorityclaim[0].docnumber.Text = new[] {"1"}; });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task DoesNotIgnoreProceduralStepChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x =>
            {
                x.proceduraldata[0].proceduralstep[0].proceduralstepdate[0].date.Text[0]
                    = Fixture.Today().ToString("yyyyMMdd");
            });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task DoesNotIgnoreProceedingLangChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x =>
            {
                var langNode = x.proceduraldata[0].proceduralstep.SingleOrDefault(_ => _.proceduralstepcode.Text[0] == "PROL");
                if (langNode != null)
                {
                    langNode.proceduralsteptext[0].Text[0] = "gr";
                }
            });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task DoesNotIgnoreTitleChanges()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Modify(v1Raw, x => { x.bibliographicdata.inventiontitle[0].Text = new[] {"New Title"}; });

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.NotEqual(v1, v2);
        }

        [Fact]
        public async Task IgnoresMateriallyInsignificantContent()
        {
            var v1Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v1.xml");
            var v2Raw = Tools.ReadFromEmbededResource(AssetPath + "applicationdetails.v2.xml");

            var v1 = await new VersionableContentResolverFixture()
                           .WithRawContent(v1Raw)
                           .Subject
                           .Resolve(new DataDownload());

            var v2 = await new VersionableContentResolverFixture()
                           .WithRawContent(v2Raw)
                           .Subject
                           .Resolve(new DataDownload());

            Assert.Equal(v1, v2);
            Assert.NotEqual(v1Raw, v2Raw);
        }
    }
}