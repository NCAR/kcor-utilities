; docformat = 'rst'

pro kcor_utils_doc
  compile_opt strictarr

  root = mg_src_root()
  idldoc, root=filepath('src', root=root), $
          output=filepath('api-userdocs', root=root), $
          /user, $
          title='KCor utilities', $
          subtitle='API documentation'
end
