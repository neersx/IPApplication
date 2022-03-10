using System;
using System.Collections.Generic;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class MarkEventBuilder : IBuilder<XElement>
    {
        public DateTime? EventDate { get; set; }

        public string EventCode { get; set; }

        public string CommentText { get; set; }

        public string EventDescription { get; set; }

        public XElement Build()
        {
            return new XElement(Ns.Trademark + "MarkEvent",
                                new XElement(Ns.Trademark + "MarkEventDate", (EventDate ?? Fixture.Today()).ToString("yyyy-MM-dd")),
                                new XElement(Ns.Trademark + "MarkEventCategory", CommentText ?? Fixture.String()),
                                new XElement(Ns.Trademark + "NationalMarkEvent",
                                             new XElement(Ns.Trademark + "MarkEventCode", EventCode ?? Fixture.String()),
                                             new XElement(Ns.Trademark + "MarkEventDescriptionText", EventDescription ?? Fixture.String()))
                               );
        }
    }

    public class MarkEventBagBuilder : IBuilder<XElement>
    {
        public MarkEventBagBuilder()
        {
            MarkEvents = new List<XElement>();
        }

        public List<XElement> MarkEvents { get; set; }

        public XElement Build()
        {
            return new XElement(Ns.Trademark + "MarkEventBag",
                                MarkEvents ?? new List<XElement>()
                               );
        }

        public MarkEventBagBuilder WithMarkEvent(string code, string description, DateTime? date = null, string comments = null)
        {
            MarkEvents.Add(new MarkEventBuilder
            {
                EventCode = code,
                EventDescription = description,
                EventDate = date,
                CommentText = comments
            }.Build());
            return this;
        }
    }
}