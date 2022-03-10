using System;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class NameTypeBuilder : IBuilder<NameType>
    {
        public int? Id { get; set; }
        public string NameTypeCode { get; set; }
        public string Name { get; set; }
        public DateTime? DateCeased { get; set; }
        public string PathNameType { get; set; }
        public string PathRelationship { get; set; }
        public decimal? HierarchyFlag { get; set; }
        public bool UseHomeNameRelationship { get; set; }
        public bool? BulkEntryFlag { get; set; }
        public short? PickListFlags { get; set; }
        public decimal? IsNameRestricted { get; set; }
        public string KotTextType { get; set; }
        public int? Program { get; set; }
        public short PriorityOrder { get; set; }
        public decimal? ShowNameCode { get; set; }

        public NameType Build()
        {
            return new NameType(
                                Id ?? Fixture.Integer(),
                                NameTypeCode ?? Fixture.String("Id"),
                                Name ?? Fixture.UniqueName())
            {
                PathNameType = PathNameType,
                PathRelationship = PathRelationship,
                HierarchyFlag = HierarchyFlag,
                UseHomeNameRelationship = UseHomeNameRelationship,
                PickListFlags = PickListFlags,
                IsNameRestricted = IsNameRestricted,
                PriorityOrder = PriorityOrder,
                KotTextType = KotTextType,
                Program = Program,
                ShowNameCode = ShowNameCode
            };
        }
    }

    public static class NameTypeBuilderExt
    {
        public static NameTypeBuilder WithUsageFlags(this NameTypeBuilder builder, short usageFlags)
        {
            if (builder == null) throw new ArgumentNullException("builder");

            builder.PickListFlags = usageFlags;
            return builder;
        }
    }
}