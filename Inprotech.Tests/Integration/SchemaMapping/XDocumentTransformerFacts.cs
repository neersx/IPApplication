using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class XDocumentTransformerFacts
    {
        public XDocumentTransformerFacts()
        {
            _transformer = new XDocumentTransformer();
        }

        readonly XDocumentTransformer _transformer;

        [Fact]
        public void ShouldAddGrandChildrenIfElementIsChoice()
        {
            var mappingEntryLookup = Substitute.For<IMappingEntryLookup>();
            var xmlValueFormatter = Substitute.For<IXmlValueFormatter>();
            var context = Substitute.For<ILocalContext>();
            const string ns = "http://www.cpaglobal.com";

            var rootNode = new XmlGenNode
            {
                Name = "root",
                Namespace = ns,
                Context = context,
                Children = new List<XmlGenNode>
                {
                    new XmlGenNode
                    {
                        Name = "child1",
                        Namespace = ns,
                        FixedValue = "a",
                        Context = context
                    }
                }
            };

            var choiceNode = new Choice(new XmlSchemaChoice());
            var choiceGenNode = new XmlGenNode(mappingEntryLookup, xmlValueFormatter, rootNode, choiceNode, null);
            choiceGenNode.Children.Add(new XmlGenNode
            {
                Name = "child21",
                Namespace = ns,
                Context = context,
                FixedValue = "C1"
            });

            choiceGenNode.Children.Add(new XmlGenNode
            {
                Name = "child22",
                Namespace = ns,
                Context = context,
                FixedValue = "C2"
            });

            rootNode.Children.Add(choiceGenNode);

            var root = _transformer.Transform(rootNode).Elements().Single();
            Assert.Equal(3, root.Elements().Count());
        }

        [Fact]
        public void ShouldBuildAttributeAndContent()
        {
            var context = Substitute.For<ILocalContext>();
            context.GetDocItemValue(null).ReturnsForAnyArgs("a");

            var root = _transformer.Transform(new XmlGenNode
            {
                Name = "root",
                Namespace = string.Empty,
                Context = context,
                Children = new List<XmlGenNode>
                {
                    new XmlGenNode
                    {
                        Name = "child",
                        Namespace = string.Empty,
                        IsAttribute = true,
                        Context = context
                    }
                }
            }).Elements().Single();

            var child = root.Attributes().Single();

            Assert.Equal("a", root.Value);
            Assert.Equal("child", child.Name);
            Assert.Equal("a", child.Value);
        }

        [Fact]
        public void ShouldBuildElement()
        {
            var context = Substitute.For<ILocalContext>();
            context.GetDocItemValue(null).ReturnsForAnyArgs("a");
            const string ns = "http://www.cpaglobal.com";

            var root = _transformer.Transform(new XmlGenNode
            {
                Name = "root",
                Namespace = ns,
                Context = context,
                Children = new List<XmlGenNode>
                {
                    new XmlGenNode
                    {
                        Name = "child",
                        Namespace = ns,
                        Context = context
                    }
                }
            }).Elements().Single();

            var child = root.Elements().Single();

            Assert.Equal("root", root.Name.LocalName);
            Assert.Equal(ns, root.Name.NamespaceName);
            Assert.Equal("child", child.Name.LocalName);
            Assert.Equal(ns, child.Name.NamespaceName);
            Assert.Equal("a", child.Value);
        }

        [Fact]
        public void ShouldIgnoreNodesWithoutValue()
        {
            var context = Substitute.For<ILocalContext>();
            const string ns = "http://www.cpaglobal.com";

            var root = _transformer.Transform(new XmlGenNode
            {
                Name = "root",
                Namespace = ns,
                Context = context,
                Children = new List<XmlGenNode>
                {
                    new XmlGenNode
                    {
                        Name = "child1",
                        Namespace = ns,
                        FixedValue = "a",
                        Context = context
                    },
                    new XmlGenNode
                    {
                        Name = "child2",
                        Namespace = ns,
                        Context = context,
                        Children = new List<XmlGenNode>
                        {
                            new XmlGenNode
                            {
                                Name = "child21",
                                Namespace = ns,
                                Context = context
                            }
                        }
                    }
                }
            }).Elements().Single();

            Assert.Single(root.Elements());
        }
    }
}