using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum ProfileAttributeType
    {
        NotSet = -1,
        MinimumImportanceLevel = 1,
        DefaultCaseProgram = 2,
        DefaultNameProgram = 3,
        DefaultCrmNamesProgram = 4
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix")]
    [Table("PROFILEATTRIBUTES")]
    public class ProfileAttribute
    {
        [Obsolete("For persistence only.")]
        public ProfileAttribute()
        {
        }

        public ProfileAttribute(Profile profile, ProfileAttributeType attributeType, string value)
        {
            if(profile == null) throw new ArgumentNullException("profile");

            ProfileId = profile.Id;
            InternalAttributeId = (int)attributeType;
            Value = value;
        }

        [Column("PROFILEID")]
        public int ProfileId { get; set; }

        [Column("ATTRIBUTEID")]
        public int InternalAttributeId { get; set; }

        public ProfileAttributeType AttributeType
        {
            get { return (ProfileAttributeType)InternalAttributeId; }
        }

        [Required]
        [MaxLength(254)]
        [Column("ATTRIBUTEVALUE")]
        public string Value { get; set; }

        public virtual Profile Profile { get; protected set; }
    }
}