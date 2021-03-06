<?php

namespace App\Model;

use Nette;


class MdRepository
{
	use Nette\SmartObject;

	/** @var Nette\Database\Context */
	private $db;
    /** @var Nette\Security\User */
    private $user;

	public function __construct(Nette\Database\Context $db, Nette\Security\User $user) 
	{
		$this->db = $db;
        $this->user = $user;
	}

    public function isRight2MdRecord($md, $right) {
        if ($this->user->isInRole('admin')) {
            return TRUE;
        }
        switch ($right) {
            case 'read':
                if($md->data_type > 0) {
                    return TRUE;
                }
                if($this->user->isLoggedIn()) {
                    if($md->create_user == $this->user->getIdentity()->username) {
                        return TRUE;
                    }
                    if($this->user->isLoggedIn()) {
                        foreach ($this->user->getIdentity()->data['groups'] as $row) {
                            if ($row == $md->view_group) {
                                return TRUE;
                            }
                            if ($row == $md->edit_group) {
                                return TRUE;
                            }
                        }
                    }
                }
                return FALSE;
                break;
            case 'write':
                if($this->user->isLoggedIn()) {
                    if($md->create_user == $this->user->getIdentity()->username) {
                        return TRUE;
                    }
                    if($this->user->isLoggedIn()) {
                        foreach ($this->user->getIdentity()->data['groups'] as $row) {
                            if ($row == $md->edit_group) {
                                return TRUE;
                            }
                        }
                    }
                }
                return FALSE;
                break;
            default:
                return FALSE;
        }
    }
	public function getXmlById($id)
	{
        return $this->db->query('SELECT pxml AS xml FROM md WHERE uuid=?', $id)->fetch();
	}

	public function getFullMdValues($md, $appLang)
	{
        return $this->db->query("
        	SELECT md_values.md_value, md_values.md_id, md_values.md_path,  md_values.lang, md_values.package_id, elements.form_code, elements.el_id, elements.from_codelist
			FROM (elements RIGHT JOIN tree ON elements.el_id = tree.el_id) RIGHT JOIN md_values ON tree.md_id = md_values.md_id
			WHERE md_values.recno=? AND (md_values.lang='xxx' OR md_values.lang='uri' OR md_values.lang=?)
            ORDER BY tree.md_left, md_values.md_path
            ", $md->recno,$appLang)->fetchAll();
	}

	public function getElementsLabel($mds,$appLang)
	{
        $tree = $this->db->query('SELECT md_left, md_right FROM tree WHERE md_id=0 AND md_standard=?', 
                $mds == 10 ? 0 : $mds)->fetch();
        $result = $this->db->query("
			SELECT elements.el_id, elements.el_name, elements.el_short_name, elements.only_value, tree.md_id,
				tree.md_level, tree.package_id, label.label_text, label.label_help
			FROM (label INNER JOIN elements ON label.label_join = elements.el_id) INNER JOIN tree ON elements.el_id = tree.el_id
			WHERE tree.md_left>=?  AND tree.md_right<=? AND label.lang=? AND label.label_type='EL' AND tree.md_standard=?
            ORDER BY tree.md_left
		", $tree->md_left, $tree->md_right, $appLang, $mds == 10 ? 0 : $mds)->fetchAll();
        return $result;
    }
    
    public function getCodeListLabel($appLang) {
        return $this->db->query("
            SELECT label.label_text
            FROM codelist INNER JOIN label ON codelist.codelist_id = label.label_join
            WHERE label.label_type='CL' AND label.lang=?
		", $appLang)->fetchAll();
    }
    
    public function getLangsLabel($appLang) {
        return $this->db->query("
			SELECT codelist.codelist_domain, label.label_text
			FROM (label INNER JOIN codelist ON label.label_join = codelist.codelist_id)
				LEFT JOIN codelist_my ON codelist.codelist_id = codelist_my.codelist_id
            WHERE label.label_type='CL' AND codelist.el_id=390 AND codelist_my.is_vis=1 AND label.lang=?
		", $appLang)->fetchPairs();
    }
    
    public function getStandardsLabel($appLang, $all=FALSE) {
        $union = $all 
                ? "UNION SELECT 99, label_text FROM label 
                   WHERE label.label_type='SD' AND label.lang='$appLang' AND label_join=99" 
                : '';
        return $this->db->query("
			SELECT standard.md_standard, label.label_text
			FROM standard INNER JOIN label ON standard.md_standard = label.label_join
            WHERE standard.is_vis=1 AND label.label_type='SD' AND label.lang=? $union
		", $appLang)->fetchPairs();
    }
    
    public function findMdById($id) {
        return $this->db->query("SELECT * FROM md WHERE uuid=?", $id)->fetchAll();
    }
    
    public function findEditMdById($id) {
        return $this->db->query("SELECT * FROM edit_md WHERE sid=? AND uuid=?",session_id(),$id)->fetchAll();
    }
    
    public function findEditMdValuesById($id) {
        return $this->db->query("
                SELECT recno,md_id,md_value,md_path,lang,package_id
                FROM edit_md_values
                WHERE recno=(SELECT recno FROM edit_md WHERE sid=? AND uuid=?)
                ORDER BY md_path
            ",session_id(),$id)->fetchAll();
    }
    
    public function findContacts() {
        return $this->db->query("SELECT * FROM contacts ORDER BY cont_label")->fetchAll();
    }
    
    public function getMdTitle($md_values,$appLang) {
        $title_app = '';
        $title_eng = '';
        $title_other = '';
        foreach ($md_values as $row) {
            if ($row->md_id == 11) {
                $title_other = $row->md_value;
                if ($row->lang == $appLang) {
                    $title_app = $row->md_value;
                }
                if ($row->lang == 'eng') {
                    $title_eng = $row->md_value;
                }
            }
        }
        if ($title_app != '') {
            $rs = $title_app;
        } elseif ($title_eng != '') {
            $rs = $title_eng;
        } else {
            $rs = $title_other;
        }
        return $rs;
    }

    public function getMdProfils($appLang, $mds=0) {
        return $this->db->query("
                SELECT profil_id, CASE WHEN label_text IS NULL THEN profil_name ELSE label_text END AS label_text
                FROM profil_names z LEFT JOIN (SELECT label_join,label_text FROM label WHERE lang=? AND label_type='PN') s
                ON z.profil_id=s.label_join
                WHERE md_standard=? AND is_vis=1
            ", $appLang, $mds)->fetchPairs('profil_id', 'label_text');
    }
    
    public function getMdPackages($appLang, $mds, $profil, $pairs=FALSE) {
        $is_packages = 0;
        if ($mds == 0 || $mds == 10) {
            $is_packages = $this->db->query("SELECT is_packages FROM profil_names
                WHERE md_standard=? AND profil_id=?", $mds, $profil)->fetchField();
        } else {
            return [];
        }
        if ($is_packages == 0) {
            return [];
        }
        if ($mds == 10) {
            $mds = 0;
        }
        $sql = "
            SELECT packages.package_id, label.label_text
            FROM packages INNER JOIN label ON packages.package_id=label.label_join
            WHERE label.label_type='MB' AND packages.md_standard=? AND label.lang=?
            ORDER BY packages.package_order
        ";
        if ($pairs) {
            return $this->db->query($sql, $mds, $appLang)->fetchPairs('package_id', 'label_text');
        } else {
            return $this->db->query($sql, $mds, $appLang)->fetchAll();
        }
        return $rs;
    }
    
    public function mdControl($xmlSource, $appLang){
        if ($xmlSource == '') {
            return array();
        }
        include("validator/resources/Validator.php");
        $validator = new \Validator("gmd", $appLang);
        $validator->run($xmlSource);
        $a = $validator->asArray();
        for($i=0;$i<count($a);$i++){
            if (isset($a[$i]['description'])) {
                $d = explode('(',$a[$i]['description']);
                $a[$i]['description'] = $d[0];
            }
        }
        return $a;
    }
    
    private function getNewRecno($mode='edit') {
        $table = $mode == 'edit' ? 'edit_md' : 'md';
        $recno = $this->db->query("SELECT MAX(recno)+1 FROM $table")->fetchField();
        return $recno > 1 ? $recno : 1;
        
    }
    
    public function copyMd2EditMdById($id, $mode='edit') {
        $this->deleteEditMd();
        $md = $this->findMdById($id);
        if ($mode == 'clone') {
            if ($this->isRight2MdRecord($md, 'read')) {
                $id = getUuid();
                $editRecno = $this->getNewRecno();
                $this->db->query("
                    INSERT INTO edit_md (sid,recno,uuid,md_standard,lang,data_type,create_user,create_date,edit_group,view_group,x1,y1,x2,y2,the_geom,range_begin,range_end,md_update,title,server_name,xmldata,pxml,valid)
                    SELECT ?,?,?,md_standard,lang,-1,?,?,?,?,x1,y1,x2,y2,the_geom,range_begin,range_end,md_update,title,server_name,xmldata,pxml,valid
                    FROM md WHERE recno=?"
                    , session_id(), $editRecno, $id, $this->user->identity->username, Date("Y-m-d"),
                        $this->user->identity->username, $this->user->identity->username, $md[0]->recno);
                $this->db->query("
                    INSERT INTO edit_md_values (recno, md_id, md_value, md_path, lang , package_id)
                    SELECT ?, md_id, md_value, md_path, lang , package_id 
                    FROM md_values WHERE recno=?"
                    , $editRecno, $md[0]->recno);
            }
            return $id;
        }
        if ($this->isRight2MdRecord($md, 'write')) {
            $editRecno = $this->getNewRecno();
            $this->db->query("
                INSERT INTO edit_md (sid,recno,uuid,md_standard,lang,data_type,create_user,create_date,edit_group,view_group,x1,y1,x2,y2,the_geom,range_begin,range_end,md_update,title,server_name,xmldata,pxml,valid)
                SELECT ?,?,uuid,md_standard,lang,data_type,create_user,create_date,edit_group,view_group,x1,y1,x2,y2,the_geom,range_begin,range_end,md_update,title,server_name,xmldata,pxml,valid
                FROM md WHERE recno=?"
                , session_id(), $editRecno, $md[0]->recno);
            $this->db->query("
                INSERT INTO edit_md_values (recno, md_id, md_value, md_path, lang , package_id)
                SELECT ?, md_id, md_value, md_path, lang , package_id 
                FROM md_values WHERE recno=?"
                , $editRecno, $md[0]->recno);
        }
        return $id;
    }
    
	public function deleteEditMd()
	{
        $this->db->query('DELETE FROM edit_md_values WHERE recno IN(SELECT recno FROM edit_md WHERE sid=?)', session_id());
        $this->db->query('DELETE FROM edit_md WHERE sid=?', session_id());
        return;
	}
    
	public function deleteMdById($id)
	{
        $md = $this->findMdById($id);
        if ($this->isRight2MdRecord($md, 'write')) {
            $this->db->query('DELETE FROM md_values WHERE recno IN(SELECT recno FROM md WHERE uuid=?)', $id);
            $this->db->query('DELETE FROM md WHERE uuid=?', $id);
            return TRUE;
        }
        return FALSE;
	}
    
    private function setNewEditMdRecord() {
        $data['sid'] = session_id();
		$data['recno'] = $this->getNewRecno();
        $data['uuid'] = getUuid();
		$data['md_standard'] = 0;
        $data['lang'] = 'cze|eng';
		$data['data_type'] = -1;
		$data['create_user'] = $this->user->identity->username;
		$data['create_date'] = Date("Y-m-d");
        $data['edit_group'] = $this->user->identity->username;
        $data['view_group'] = $this->user->identity->username;
        $this->db->query("INSERT INTO edit_md", $data);
        
		if ($data['md_standard'] == 0 || $data['md_standard'] == 10) {
            $this->db->query("INSERT INTO edit_md_values", [
                [
                'recno'=>$data['recno'],
                'md_value'=>$data['uuid'],
                'md_id'=>38,
                'md_path'=>'0_0_38_0',
                'lang'=>'xxx',
                'package_id'=>0
                ], [
                'recno'=>$data['recno'],
                'md_value'=>'cze',
                'md_id'=>5527,
                'md_path'=>'0_0_39_0_5527_0',
                'lang'=>'xxx',
                'package_id'=>0
                ], [
                'recno'=>$data['recno'],
                'md_value'=>Date("Y-m-d"),
                'md_id'=>44,
                'md_path'=>'0_0_44_0',
                'lang'=>'xxx',
                'package_id'=>0
                ]
            ]);
		}
		return $data['uuid'];
    }
    
    public function createNewMdRecord($param) {
        $this->deleteEditMd();
        return $this->setNewEditMdRecord();
    }
    
    public function setEditMdValues($formValues) {
		$uuid = ($formValues['uuid'] != '') ? $formValues['uuid'] : '';
		$recno = ($formValues['recno'] != '') ? $formValues['recno'] : -1;
		$block = ($formValues['block'] != '') ? $formValues['block'] : -1;
		$nextblock = ($formValues['nextblock'] != '') ? $formValues['nextblock'] : -1;
		$profil = ($formValues['profil'] != '') ? $formValues['profil'] : -1;
		$nexprofil = ($formValues['nextprofil'] != '') ? $formValues['nextprofil'] : -1;
		$mds = ($formValues['mds'] != '') ? $formValues['mds'] : -1;
		$data_type = isset($formValues['data_type']) ? $formValues['data_type'] : -1;
        $edit_group = isset($formValues['edit_group']) ? $formValues['edit_group'] : '';
        $view_group = isset($formValues['view_group']) ? $formValues['view_group'] : '';
        if ($recno < 1 || count($formValues) < 6 || $mds < 0) {
            throw new \Nette\Application\AbortException;
        }
        $md = $this->findEditMdById($uuid);
        if (!$this->isRight2MdRecord($md, 'write')) {
            throw new \Nette\Application\ForbiddenRequestException;
        }

        if (array_key_exists('fileIdentifier_0_TXT', $formValues)) {
            // micka lite
            
        } else {
            $data = array();
            $data['data_type'] = $data_type;
            if ($edit_group != '') {
                $data['edit_group'] = $edit_group;
            }
            if ($view_group != '') {
                $data['view_group'] = $view_group;
            }
            //$this->updateEditMd($recno, $data);
            //$pom = getProfilPackages($mds, $profil, $block);
            //$this->deleteMdValues($recno, $mds, $pom['profil'], $pom['package']);
            
        }
        
    }
}
