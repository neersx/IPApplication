using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Configuration
{
    [Table("Link")]
    public class Link
    {
        [Obsolete("For persistence only.")]
        public Link()
        {
        }

        public Link(TableCode category, string url, 
                    string title = null, string description = null, 
                    short displaySequence = 0, 
                    bool isExternal = false, 
                    User user = null, AccessAccount accessAccount = null) : this(category)
        {
            if (category == null) throw new ArgumentNullException(nameof(category));

            Url = url;
            Title = title;
            Description = description;
            DisplaySequence = displaySequence;
            IdentityId = user?.Id;
            AccessAccountId = accessAccount?.Id;
            IsExternal = isExternal;
        }
        
        public Link(TableCode category)
        {
            if (category == null) throw new ArgumentNullException(nameof(category));
            CategoryId = category.Id;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        [Column("LINKID")]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(254)]
        [Column("URL")]
        public string Url { get; set; }
        
        [Required]
        [MaxLength(100)]
        [Column("TITLE")]
        public string Title { get; set; }
        
        [Column("TITLE_TID")]
        public int? TitleTid { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short DisplaySequence { get; set; }

        [Column("CATEGORYID")]
        public int CategoryId { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Column("ACCESSACCOUNTID")]
        public int? AccessAccountId { get; set; }

        [Column("ISEXTERNAL")]
        public bool? IsExternal { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTid { get; set; }
    }
}