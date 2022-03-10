using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Web.Builders.Model.Common
{
    public class SiteControlBuilder : IBuilder<SiteControl>
    {
        public string Owner { get; set; }

        public int? Id { get; set; }

        public string SiteControlId { get; set; }

        public string SiteControlDescription { get; set; }

        public int? IntegerValue { get; set; }

        public string StringValue { get; set; }

        public bool? BooleanValue { get; set; }

        public decimal? DecimalValue { get; set; }

        public DateTime? DateValue { get; set; }

        public string Notes { get; set; }
        public List<Tag> Tags { get; set; }

        public object Value { get; set; }

        public SiteControl Build()
        {
            var cId = string.IsNullOrEmpty(SiteControlId) ? Fixture.String() : SiteControlId;
            if (Value != null)
            {
                SetValue();
            }

            SiteControl siteControl;
            if (IntegerValue.HasValue)
            {
                siteControl = new SiteControl(cId, IntegerValue) {DataType = "I"};
            }
            else if (BooleanValue.HasValue)
            {
                siteControl = new SiteControl(cId, BooleanValue) {DataType = "B"};
            }
            else if (DecimalValue.HasValue)
            {
                siteControl = new SiteControl(cId, DecimalValue) {DataType = "D"};
            }
            else
            {
                siteControl = new SiteControl(cId, StringValue) {DataType = "C"};
            }

            siteControl.StringValue = siteControl.StringValue ?? string.Empty;

            siteControl.Id = Id ?? Fixture.Integer();
            siteControl.Notes = Notes;
            siteControl.Tags = Tags ?? new List<Tag>();
            siteControl.SiteControlDescription = SiteControlDescription ?? string.Empty;

            return siteControl;
        }

        void SetValue()
        {
            if (Value is int)
            {
                IntegerValue = (int) Value;
            }

            if (Value is decimal)
            {
                DecimalValue = (decimal) Value;
            }

            if (Value is bool)
            {
                BooleanValue = (bool) Value;
            }

            var s = Value as string;
            if (s != null)
            {
                StringValue = s;
            }
        }
    }
}