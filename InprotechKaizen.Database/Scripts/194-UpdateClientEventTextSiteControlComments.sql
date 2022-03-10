UPDATE dbo.SITECONTROL
  SET
      COMMENTS = 'Determines whether or not Event Notes entered without a Event Note Type are visible to your firms external users (your Clients). If set to TRUE, your clients are able to view Event Notes without an Event Note type.
This site control does not affect Event Notes which have an Event Note Type entered against them because they are controlled by the public flag set against the note type.'
WHERE CONTROLID = 'Client Event Text';
GO