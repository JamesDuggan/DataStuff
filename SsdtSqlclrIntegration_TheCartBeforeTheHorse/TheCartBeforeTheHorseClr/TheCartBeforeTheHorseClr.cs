//------------------------------------------------------------------------------
// <copyright file="CSSqlStoredProcedure.cs" company="Microsoft">
//     Copyright (c) Microsoft Corporation.  All rights reserved.
// </copyright>
//------------------------------------------------------------------------------
using System;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class TheCartBeforeTheHorse
{
   [Microsoft.SqlServer.Server.SqlProcedure]
   public static void DeleteXEventSessionFile(SqlString targetFilePath, SqlString sessionName)
   {
      foreach (var f in Directory.GetFiles((string)targetFilePath, String.Format("{0}*.*", sessionName)))
      {
         File.Delete(f);
      }
   }
}
